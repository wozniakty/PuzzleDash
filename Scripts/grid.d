module grid;

import core, components, utility;
import gl3n.linalg;

public enum Color
{
	Empty,
	Red,
	Yellow,
	Green,
	Purple,
	Blue,
	White,
	Black
}

public enum TILE_SIZE = 64;

shared final class Grid : GameObject
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

		state = new shared Tile[size];
		selection = shared vec2i( -1, -1 );
	}


	@property const int size() 
	{ 
		return rows * cols; 
	}

	shared(Tile) opIndex( int n )
	{
		if( n < 0 || n > size - 1 )
			return new shared Tile;
		return state[n];
	}

	shared(Tile) opIndex( int row, int col )
	{
		return state[rcToN( row, col )];
	}

	void opIndexAssign( shared Tile t, int n )
	{
		if( n >= 0 && n > size )
			state[n] = t;
	}

	void opIndexAssign( shared Tile t, int row, int col )
	{
		this[ rcToN( row, col ) ] = t;
	}

	int rcToN( int row, int col )
	{
		return( row * cols ) + col;
	}

	shared(vec2i) nToRc( int n )
	{
		return shared vec2i( n / cols, n % cols );
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

			this[i] = new shared Tile( next );
		}
	}

	public Color randomColor()
	{	
		// Totally random
		return Color.Blue;
	}
}

shared class Tile : GameObject
{
public:
	Color color;

	this( Color c )
	{
		color = c;
	}

	this()
	{
		color = Color.Empty;
	}

private:
	Grid container;
}