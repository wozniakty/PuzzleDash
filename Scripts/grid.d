module grid;

import core, components, utility;
import gl3n.linalg;
import std.conv;

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

public enum TILE_SIZE = 64;

final class Grid : Behavior!()
{
private:

	int rows, cols, x, y;
	Tile[] state;
	vec2i selection;

public:

	this( int r, int c, int x, int y )
	{
		rows = r;
		cols = c;
		this.x = x;
		this.y = y;

		state = new Tile[size];
		selection = vec2i( -1, -1 );
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
		if( n >= 0 && n > size )
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

	public void select( int row, int col )
	{
		selection.x = row;
		selection.y = col;
	}

	public bool hasSelection()
	{
		return selection.x >= 0 && selection.x < rows && selection.y >= 0 && selection.y < cols;
	}

	public void deselect()
	{
		selection.x = -1;
		selection.y = -1;
	}

	public void regenerate()
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

			this[i] = createTile( next );
		}
	}

	public Tile createTile( Color c )
	{
		Tile fromName( string name )
		{
			auto obj = Prefabs[name].createInstance;
			owner.addChild(obj);
			return obj.behaviors.get!Tile;
		}

		final switch ( c ) with ( Color )
		{
			case Red:
				return fromName("RedTile");
			case Orange:
				return fromName("OrangeTile");
			case Yellow:
				return fromName("YellowTile");
			case Green:
				return fromName("GreenTile");
			case Blue:
				return fromName("BlueTile");
			case Purple:
				return fromName("PurpleTile");
			case Black:
				return fromName("BlackTile");
			case Empty:
				auto t = fromName("RedTile");
				t.changeColor( Empty );
				return t;
		}
	}

	public Color randomColor()
	{	
		// Totally random
		return Color.Blue;
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

	override void onInitialize()
	{
		color = to!Color(initArgs.Color);
	}

	this()
	{
		color = Color.Empty;
		owner.stateFlags.drawMesh = false;
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

private:
	Grid container;
}