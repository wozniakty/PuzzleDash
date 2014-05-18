module grid;

import core, components, utility;
import gl3n.linalg, gl3n.math, gl3n.interpolate;
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

public enum GameStep
{
    Input,
    CheckMatch,
    CheckDeadlock
}

public enum TILE_SIZE = 4.5f;
public enum FALL_TIME = .2f;

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
    GameStep step;
    vec2i previousSwap;
    int lowestEmpty;
    bool debugMode;
    PointLight highlight;

public:

    override void onInitialize()
    {
        rows = initArgs.Rows;
        cols = initArgs.Cols;
        step = GameStep.Input;

        state = new Tile[size];
        selection = -1;
        regenerate();

        auto hl = Prefabs["Highlight"].createInstance;
        owner.addChild(hl);
        highlight = cast(PointLight)(hl.light);

        Input.addKeyDownEvent( Keyboard.MouseLeft, &mouseDown );
    }

    this()
    {
        rows = 1;
        cols = 1;
        debugMode = false;
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
        return this[rcToN( row, col )];
    }

    void opIndexAssign( Tile t, int n )
    {
        if( n >= 0 && n < size )
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
        selection = rcToN( row, col );
    }

    void select( int n )
    {
        selection = n;
    }

    bool hasSelection()
    {
        return selection > -1 && selection < size;
    }

    void deselect()
    {
        selection = -1;
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
            t.owner.transform.position.x = pos.y * TILE_SIZE;
            t.owner.transform.position.z = pos.x * TILE_SIZE;
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
        auto p1 = t1.position;
        auto p2 = t2.position;
        t1.moveTo( p2 );
        t2.moveTo( p1 );
        t1.index = n2;
        t2.index = n1;

        this[n2] = t1;
        this[n1] = t2;
    }

    void clearTiles( Match match )
    {
        logDebug( "Clearing tiles: ", match.indeces );

        foreach( index; match.indeces )
        {
            this[index].changeColor( Color.Empty );
        }
    }

    Match[] findMatches()
    {
        //Reference to the current match at each tile
        Match[int] matchSet;
        // List of all discrete unconnected matches
        Match[] matches;

        // First deal with horizontal matches
        for( int i = 0; i < size; i++ )
        {
            auto hor = findMatchHorizontal( i );
            if( hor.indeces.length > 0 )
            {
                foreach( index; hor.indeces )
                {
                    matchSet[index] = hor;
                }
                matches ~= hor;

                i += hor.indeces.length;
            }
        }

        // Now that we have those, iterate through the list and handle verticals

        for( int j = 0; j < size; j++ )
        {
            //I make a dummy i that goes down the columns, since that check is more efficient
            int i = ( j / rows ) + ( ( j % rows ) * cols );
            auto ver = findMatchVertical( i );

            if( ver.indeces.length > 0 )
            {
                //Let's get all the Matches that this match collides with
                Match[] collisions;
                foreach( index; ver.indeces )
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
                    foreach( index; ver.indeces )
                    {
                        if( match.indeces.countUntil( index ) < 0 )
                        {
                            match.indeces ~= index;
                            matchSet[index] = match;
                        }
                    }
                }
                else if( collisions.length > 1 )
                {
                    auto match = new Match;
                    foreach( col; collisions )
                    {
                        foreach( index; col.indeces )
                        {
                            matchSet[index] = match;
                        }
                        match.indeces ~= col.indeces;
                        matches.remove( matches.countUntil( col ) );
                    }

                    foreach( index; ver.indeces )
                    {
                        if( match.indeces.countUntil( index ) < 0 )
                        {
                            match.indeces ~= index;
                            matchSet[index] = match;
                        }
                    }
                }
                else
                {
                    //If no collision, just create the match and add it to the list
                    foreach( index; ver.indeces )
                    {
                        matchSet[index] = ver;
                    }

                    matches ~= ver;
                }

                //And finally, move our index along by the length
                j += ver.indeces.length;
            }
        }
        return matches;
    }

    Match findMatchHorizontal( int n )
    {
        int length = 0;
        if( this[n].color != Color.Empty )
        {
            length = 1;
            for( int i = 1; i < cols - ( n % cols ); i++ )
            {
                if( this[n].color == this[n + i].color )
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

        auto match = new Match;
        for( int i = 0; i < length; i++ )
        {
            match.indeces ~= n + i;
        }
        return match;
    }

    Match findMatchVertical( int n )
    {
        int length = 0;
        if( this[n].color != Color.Empty )
        {
            length = 1;
            for( int i = 1; i < rows - ( n / cols ); i++ )
            {
                if( this[n].color == this[n + cols * i].color )
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

        auto match = new Match;
        for( int i = 0; i < length; i++ )
        {
            match.indeces ~= n + cols*i;
        }
        return match;
    }

    void refillBoard( int lowestEmp = -1 )
    {
        //Store the lowest empty tile, which will help us optimize at the end
        if( lowestEmp < 0 )
            lowestEmp = dropEmpties();

        int[] spot = new int[cols];
        spot[] = -1;
        int y = lowestEmp / cols;
        for( int i = lowestEmp; i >= 0; i-- )
        {
            if( this[i].color == Color.Empty )
            {
                auto t = createTile( randomColor() );
                t.index = i;
                t.owner.transform.position.x = ( i % cols ) * TILE_SIZE;
                t.owner.transform.position.z = spot[ i % cols ] * TILE_SIZE;
                spot[ i % cols ]--;
                t.moveTo( vec3( ( i % cols ) * TILE_SIZE, 0, ( y ) * TILE_SIZE ) );
                this[i] = t;
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
                while( above > ( 0 - cols ) )
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

    bool animating()
    {
        for( int i = 0; i < size; i++ )
        {
            if( this[i].animating )
                return true;
        }
        return false;
    }

    void mouseDown( uint keyCode )
    {
        if( !animating )
        {
            if( step == GameStep.Input )
            {
                auto selected = Input.mouseObject;
                auto tile = selected.behaviors.get!Tile;
                if( tile )
                {
                    auto index = tile.index;

                    if( !hasSelection )
                    {
                        select( index );
                    }
                    else
                    {
                        auto swaps = getSwaps( selection );
                        if( swaps.countUntil( index ) >= 0 )
                        {
                            swap( index, selection );
                            previousSwap.x = index;
                            previousSwap.y = selection;
                            deselect();
                            step = GameStep.CheckMatch;
                        }
                        else
                        {
                            if( selection == index )
                                deselect();
                            else
                                select( index );
                        }
                    }
                }
            }
        }
        else
            logDebug("Patience, I'm animating");
    }

    override void onUpdate()
    {
        debug
        {

            if( Input.getState("Space") )
            {
                debugMode = !debugMode;
            }
            if( debugMode )
            {
                if( Input.getState("Up") )
                {
                    owner.transform.position.y += 10 * Time.deltaTime;
                }
                if( Input.getState("Down") )
                {
                    owner.transform.position.y -= 10 * Time.deltaTime;
                }
                if( Input.getState("Left") )
                {
                    owner.transform.position.x -= 10 * Time.deltaTime;
                }
                if( Input.getState("Right") )
                {
                    owner.transform.position.x += 10 * Time.deltaTime;
                }
            }
        }

        if( !animating )
        {
            if( step == GameStep.CheckMatch )
            {
                auto matches = findMatches();
                if( matches.length == 0 )
                {
                    if( !debugMode )
                        swap( previousSwap.x, previousSwap.y );
                    step = GameStep.Input;
                }
                else
                {
                    foreach( match; matches )
                    {
                        clearTiles( match );
                    }

                    lowestEmpty = dropEmpties();
                    refillBoard( lowestEmpty );

                    if( findMatches().length <= 0 )
                    {
                        step = GameStep.CheckDeadlock;
                    }
                }
            }
            else if( step == GameStep.CheckDeadlock )
            {
                if( deadlocked )
                {
                    logDebug( "  THATS A DEADLOCK  ");
                    //do nothing yet
                }
                else
                {
                    step = GameStep.Input;
                    deselect();
                }
            }
        }

        for( int i = 0; i < size; i++ )
        {
            this[i].updatePosition();
        }

        if( selection > -1 )
        {
            highlight.owner.stateFlags.drawLight = true;
            auto pos = nToRc( selection );
            highlight.owner.transform.position.x = pos.y * TILE_SIZE;
            highlight.owner.transform.position.z = pos.x * TILE_SIZE;
        }
        else
        {
            highlight.owner.stateFlags.drawLight = false;
        }
    }
}

class Match
{
    int[] indeces;

    this()
    {
    }
}

class TileFields
{
    string Color;
}

class Tile : Behavior!TileFields
{
private:
    bool _animating;
    vec3 start;
    vec3 target;
    float startTime;
public:
    Color color;
    uint index;
    mixin( Property!_animating );
    
    vec3 position()
    {
        if( animating )
            return target;
        else
            return owner.transform.position;
    }

    override void onInitialize()
    {
        changeColor( to!Color(initArgs.Color) );
    }

    this()
    {
        color = Color.Empty;
    }

    void moveTo( vec3 position )
    {
        start = owner.transform.position;
        target = position;
        animating = true;
        startTime = Time.totalTime;
    }

    void updatePosition()
    {        
        if( animating )
        {
            auto fallTime = FALL_TIME * max( ( distance( start, target ) / TILE_SIZE ), 1.0f  );
            auto factor = min( ( Time.totalTime - startTime ) / fallTime, 1.0f );
            if( factor < 1.0f )
            {
                owner.transform.position = lerp( start, target, factor );
            }
            else
            {
                owner.transform.position = target;
                animating = false;
            }
        }
    }

    void changeColor( Color c )
    {
        if( owner )
        {
            color = c;
            if( c != Color.Empty )
            {
                owner.material = Assets.get!Material( to!string(c) );
                owner.stateFlags.drawMesh = true;
            }
            else
                owner.stateFlags.drawMesh = false;
        }
    }
}