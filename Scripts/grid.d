module grid;

import core, components, utility;
import gl3n.linalg, gl3n.math;
import std.conv, std.random, std.algorithm;

public enum Color
{
    Empty,
    Red,
    Orange,
    Yellow,
    Green,
    Blue,
    Purple,
    Black,
}

public enum TILE_SIZE = 4.5;

class GridArgs
{
    int Rows;
    int Cols;
}

final class Grid : Behavior!GridArgs
{
private:

    int rows, cols;
    Tile[] state;
    int selection;

public:

    override void onInitialize()
    {
        rows = initArgs.Rows;
        cols = initArgs.Cols;

        state = new Tile[size];
        selection = -1;
        regenerate();

        debug { Input.addKeyDownEvent( Keyboard.Space, ( uint kc ) { logDebug("GridPos: ", owner.transform.position); } ); }
        Input.addKeyDownEvent( Keyboard.MouseLeft, &mouseDown );
    }

    this()
    {
        rows = 1;
        cols = 1;
    }


    @property const int size() 
    { 
        return rows * cols; 
    }

    Tile opIndex( int n )
    {
        if( n < 0 || n > size - 1 )
            return new Tile;
        return state[n];
    }

    Tile opIndex( int row, int col )
    {
        return state[rcToN( row, col )];
    }

    void opIndexAssign( Tile t, int n )
    {
        if( n >= 0 && n < size - 1 )
            state[n] = t;
    }

    void opIndexAssign( Tile t, int row, int col )
    {
        this[ rcToN( row, col ) ] = t;
    }

    int rcToN( int row, int col )
    {
        return( row * cols ) + col;
    }

    vec2i nToRc( int n )
    {
        return vec2i( n / cols, n % cols );
    }

    void select( int row, int col )
    {
        select( rcToN( row, col ) );
    }

    bool hasSelection()
    {
        return selection > -1 && selection < size;
    }

    void deselect()
    {
        selection = -1;
    }

    void select( int n )
    {
        selection = n;
    }

    void regenerate()
    {
        for( int i = 0; i < size; i++ )
        {
            Color invalid1 = Color.Empty;
            Color invalid2 = Color.Empty;

            if( i % cols > 1 && this[ i - 1 ].color == this[ i - 2 ].color )
            {
                invalid1 = this[ i - 1 ].color;
            }
            if( i / cols > 1 && this[ i - cols ].color == this[ i - 2*cols ].color )
            {
                invalid2 = this[ i - cols ].color;
            }
            Color next = randomColor();
            while( invalid1 == next || invalid2 == next )
            {
                next = randomColor();
            }

            auto pos = nToRc(i);
            auto t = createTile( next );
            t.index = i;
            t.owner.transform.position.x = pos.x * TILE_SIZE;
            t.owner.transform.position.z = pos.y * TILE_SIZE;
            this[i] = t;
        }
    }

    int[] getSwaps( int n )
    {
        return [ (n / cols == 0)? -1 : n - cols,
            ( n % cols == cols - 1 )? -1 : n + 1,
            (n / cols == rows - 1)? -1 : n + cols,
            (n % cols == 0)? -1 : n - 1 ];
    }

    int[] getSwaps( int row, int col )
    {
        return getSwaps( rcToN( row, col ) );
    }

    void swap( int n1, int n2 )
    {
        auto t1 = this[n1];
        auto t2 = this[n2];
        auto p1 = t1.owner.transform.position;
        t1.owner.transform.position = t2.owner.transform.position;
        t2.owner.transform.position = p1;
        t1.index = n2;
        t2.index = n1;

        this[n2] = t1;
        this[n1] = t2;
    }

    void emptyTiles(int[] indeces)
    {
        foreach( i; indeces )
        {
            this[i].changeColor( Color.Empty );
        }
    }

    int[][] findMatches()
    {
        //Reference to the current match at each tile
        int[][int] matchSet;
        // List of all discrete unconnected matches
        int[][] matches;

        // First deal with horizontal matches
        for( int i = 0; i < size; i++ )
        {
            auto hor = findMatchHorizontal( i );
            if( hor.length > 0 )
            {
                int[] match;
                foreach( index; hor )
                {
                    match ~= index;
                    matchSet[index] = match;
                }
                matches ~= match;

                i += hor.length;
            }
        }

        // Now that we have those, iterate through the list and handle verticals

        for( int j = 0; j < size; j++ )
        {
            //I make a dummy i that goes down the columns, since that check is more efficient
            int i = ( j / rows ) + ( ( j % rows ) * cols );
            auto ver = findMatchVertical( i );

            if( ver.length > 0 )
            {
                //Let's get all the Matches that this match collides with
                int[][] collisions;
                foreach( index; ver )
                {
                    //Contains key index?
                    if( index in matchSet )
                    {
                        collisions ~= matchSet[index];
                    }
                }

                //If there is only one list, we'll just add new values from this match
                if( collisions.length == 1 )
                {
                    auto match = collisions[0];
                    foreach( index; ver )
                    {
                        if( match.countUntil( index ) >= 0 )
                        {
                            match ~= index;
                            matchSet[index] = match;
                        }
                    }
                }
                else if( collisions.length > 1 )
                {
                    int[] match;
                    foreach( col; collisions )
                    {
                        foreach( index; col )
                        {
                            //TODO: This may cause a bug in D. We'll find out later
                            matchSet[index] = match;
                        }
                        match ~= col;
                        matches.remove( collisions.countUntil( col ) );
                    }

                    foreach( index; ver )
                    {
                        if( match.countUntil( index ) >= 0 )
                        {
                            match ~= index;
                            matchSet[index] = match;
                        }
                    }
                }
                else
                {
                    //If no collision, just create the match and add it to the list
                    int[] match;
                    foreach( index; ver )
                    {
                        match ~= index;
                        matchSet[index] = match;
                    }

                    matches ~= match;
                }

                //And finally, move our index along by the length
                j += ver.length;
            }
        }

        return matches;
    }

    int[] findMatchHorizontal( int n )
    {
        int length = 0;
        if( this[n].color != Color.Empty )
        {
            length = 1;
            for( int i = n + 1; i < cols; i++ )
            {
                if( this[n].color == this[i].color )
                {
                    length++;
                }
                else
                    break;
            }

            //Matches need to be at least length 3
            if( length < 3 ) 
            {
                length = 0;
            }
        }

        int[] match = new int[length];
        for( int i = 0; i < length; i++ )
        {
            match[i] = n + i;
        }
        return match;
    }

    int[] findMatchVertical( int n )
    {
        int length = 0;
        if( this[n].color != Color.Empty )
        {
            length = 1;
            for( int i = n + 1; i < rows; i++ )
            {
                if( this[n].color == this[cols * i].color )
                {
                    length++;
                }
                else
                    break;
            }

            if( length < 3 ) 
            {
                length = 0;
            }
        }

        int[] match = new int[length];
        for( int i = 0; i < length; i++ )
        {
            match[i] = n + cols*i;
        }
        return match;
    }

    void refillBoard( int lowestEmp = -1 )
    {
        //Store the lowest empty tile, which will help us optimize at the end
        if( lowestEmp < 0 )
            lowestEmp = dropEmpties();

        int[] spot = new int[cols];
        spot[] = 0;
        int y = lowestEmp / cols;
        for( int i = lowestEmp; i >= 0; i-- )
        {
            if( this[i].color == Color.Empty )
            {
                auto t = createTile( randomColor() );
                this[i] = t;
                t.owner.transform.position.x = ( i % cols ) * TILE_SIZE;
                t.owner.transform.position.y = spot[ i % cols ] * TILE_SIZE;
                spot[ i % cols ]--;
            }

            if( i % cols == 0 ) y--;
        }
    }

    int dropEmpties()
    {
        int lowestEmp = 0;
        for( int i = size - 1; i >= 0; i-- )
        {
            //Do a check to make sure we aren't at the top of the column
            bool top = false;
            while( this[i].color == Color.Empty && !top )
            {
                top = true;
                int cur = i;
                int above = cur - cols;
                while( above > 0 - cols )
                {
                    if( this[above].color != Color.Empty )
                    {
                        top = false;
                        break;
                    }
                    else
                    {
                        above -= cols;
                    }
                }

                if( top )
                {
                    if( i > lowestEmp )
                        lowestEmp = i;
                    break;
                }
                else
                {
                    while( this[above].color != Color.Empty )
                    {
                        swap( cur, above );
                        cur -= cols;
                        above -= cols;
                    }
                }
            }
        }

        return lowestEmp;
    }

    bool deadlocked()
    {
       for (int i = 0; i < rows; i++)
            {
                for (int j = 0; j < cols; j++)
                {
                    if (this[i, j].color == this[i, j + 2].color &&
                        (this[i, j].color == this[i - 1, j + 1].color ||
                        this[i, j].color == this[i + 1, j + 1].color))
                            return false;
                    if (this[i, j].color == this[i + 2, j].color &&
                        (this[i,j].color == this[i + 1,j-1].color ||
                        this[i,j].color == this[i+1,j+1].color))
                            return false;
                    if (this[i, j].color == this[i, j + 1].color &&
                        (this[i, j].color == this[i - 1, j - 1].color ||
                        this[i, j].color == this[i, j - 2].color ||
                        this[i, j].color == this[i + 1, j - 1].color ||
                        this[i, j].color == this[i + 1, j + 2].color ||
                        this[i, j].color == this[i, j + 3].color ||
                        this[i, j].color == this[i - 1, j + 2].color))
                            return false;
                    if(this[i,j].color == this[i+1,j].color &&
                        (this[i,j].color == this[i-2,j].color ||
                        this[i,j].color == this[i-1,j-1].color ||
                        this[i,j].color == this[i+2,j-1].color ||
                        this[i,j].color == this[i+3,j].color ||
                        this[i,j].color == this[i+2,j+1].color ||
                        this[i,j].color == this[i-1,j+1].color))
                            return false;
                }
            }

            return true;
    }
 
    Tile createTile( Color c )
    {
        auto obj = Prefabs[to!string(c) ~ "Tile"].createInstance;
        owner.addChild(obj);
        return obj.behaviors.get!Tile;
    }

    Color randomColor()
    {   
        auto i = uniform( 1, 8 );
        return cast(Color)i;
    }

    void mouseDown( uint keyCode )
    {
        auto obj = Input.mouseObject;
		auto selectedTile = obj.behaviors.get!Tile;
		if( selectedTile )
		{
			
		}

    }

    override void onUpdate()
    {
        debug
        {
            if( Input.getState("Up") )
            {
                logDebug( Time.deltaTime );
                owner.transform.position.y += 10 * Time.deltaTime;
            }
            if( Input.getState("Down") )
            {
                logDebug( Time.deltaTime );
                owner.transform.position.y -= 10 * Time.deltaTime;
            }
            if( Input.getState("Left") )
            {
                logDebug( Time.deltaTime );
                owner.transform.position.x -= 10 * Time.deltaTime;
            }
            if( Input.getState("Right") )
            {
                logDebug( Time.deltaTime );
                owner.transform.position.x += 10 * Time.deltaTime;
            }
        }
    }
}

class TileFields
{
    string Color;
}

class Tile : Behavior!TileFields
{
public:
    Color color;
    uint index;

    override void onInitialize()
    {
        changeColor( to!Color(initArgs.Color) );
    }

    this()
    {
        color = Color.Empty;
    }

    void changeColor( Color c )
    {
        if( c != Color.Empty )
        {
            owner.material = Assets.get!Material( to!string(c) );
            color = c;
            owner.stateFlags.drawMesh = true;
        }
        else
            owner.stateFlags.drawMesh = false;
    }
}