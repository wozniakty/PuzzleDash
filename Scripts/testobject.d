module testobject;
import core.gameobject;
import utility.input, utility.output, utility.time;
import components;
import gl3n.linalg;
import std.random;

class TOArgs
{
    int x;
}

shared class TestObject : GameObjectInit!TOArgs
{
    override void onInitialize( TOArgs args )
    {
        import std.stdio;
        writeln( args.x );
    }

    // Overridables
    override void onUpdate()
    {
        if( Input.getState( "Forward" ) )
        {
            log( OutputType.Info, "Forward" );
        }
        if( Input.getState( "Backward" ) )
        {
            log( OutputType.Info, "Backward" );
        }
        if( Input.getState( "Jump" ) )
        {
            log( OutputType.Info, "Jump" );
        }

        /*
        auto liiiiight = (cast(DirectionalLight)this.light);

        // If you were actually thinking about doing this in your game, please don't.
        static float red = 0.0f;
        static float blu = 50.0f;
        static float gre = 100.0f;
        static float redMod = 0.1f;
        static float bluMod = 0.1f;
        static float greMod = 0.1f;

        // Change color direction
        if(red >= 100 || red < 0) redMod = -redMod;
        if(blu >= 100 || blu < 0) bluMod = -bluMod;
        if(gre >= 100 || gre < 0) greMod = -greMod;
    
        red += redMod;
        blu += bluMod;
        gre += greMod;

        liiiiight.color = vec3(red/100.0f, blu/100.0f, gre/100.0f); */
    }

    /// Called on the draw cycle.
    override void onDraw() { }
    /// Called on shutdown.
    override void onShutdown() { }
    /// Called when the object collides with another object.
    override void onCollision( GameObject other ) { }
}

shared class MovePointLight : GameObject
{
    // Overridables
    override void onUpdate()
    {
        static float t = 0.0;
        t += std.math.PI/2 * Time.deltaTime;
    //  this.transform.position = vec3( 20*cos(t), 20*sin(t), this.transform.position.z );
        //this.transform.position.x = 10*cos(t);
        //this.transform.position.y = 10*sin(t);

        //this.transform.rotation.rotatez( -std.math.PI * Time.deltaTime);
    }

    /// Called on the draw cycle.
    override void onDraw() { }
    /// Called on shutdown.
    override void onShutdown() { }
    /// Called when the object collides with another object.
    override void onCollision( GameObject other ) { }
}


shared class RotateThing : GameObject
{
    // Overridables
    override void onUpdate()
    {
        if( Input.getState( "Forward" ) )
        {
            log( OutputType.Info, "Forward" );
        }
        if( Input.getState( "Backward" ) )
        {
            log( OutputType.Info, "Backward" );
        }
        if( Input.getState( "Jump" ) )
        {
            log( OutputType.Info, "Jump" );
        }

        this.transform.rotation.rotatey( -std.math.PI * Time.deltaTime );
        //(cast()this.transform.rotation).rotatey( std.math.PI * Time.deltaTime);
        //(cast()this.transform.rotation).rotatex( -std.math.PI * Time.deltaTime);
    }
    
    /// Called on the draw cycle.
    override void onDraw() { }
    /// Called on shutdown.
    override void onShutdown() { }
    /// Called when the object collides with another object.
    override void onCollision( GameObject other ) { }
}
