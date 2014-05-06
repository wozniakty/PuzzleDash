module grid;

import core, components, utility;
import gl3n.linalg, gl3n.math;
import std.conv, std.random;

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
	vec2i selection;

public:

	override void onInitialize()
	{
		rows = initArgs.Rows;
		cols = initArgs.Cols;

		state = new Tile[size];
		selection = vec2i( -1, -1 );
		regenerate();

		debug { Input.addKeyDownEvent( Keyboard.Space, ( uint kc ) { logDebug("GridPos: ", owner.transform.position); } ); }
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
		selection.x = row;
		selection.y = col;
	}

	bool hasSelection()
	{
		return selection.x >= 0 && selection.x < rows && selection.y >= 0 && selection.y < cols;
	}

	void deselect()
	{
		selection.x = -1;
		selection.y = -1;
	}

	void updateSelection( vec2i s )
	{
		selection = s;
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

	Tile createTile( Color c )
	{
		auto obj = Prefabs[to!string(c) ~ "Tile"].createInstance;
		owner.addChild(obj);
		return obj.behaviors.get!Tile;
	}

	void swap( int n1, int n2 )
	{
		auto t1 = this[n1];
		auto t2 = this[n2];
		auto p1 = t1.owner.transform.position;
		t1.owner.transform.position = t2.owner.transform.position;
		t2.owner.transform.position = p1;

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

	Color randomColor()
	{	
		auto i = uniform( 1, 8 );
		return cast(Color)i;
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