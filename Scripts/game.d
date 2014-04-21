module game;
import core;
import graphics.graphics;
import components.camera, components.userinterface;
import utility;

import gl3n.linalg;

shared class Game : DGame
{
    Camera cam;
    
    override void onInitialize()
    {
        logInfo( "Initializing TestGame..." );

        Input.addKeyDownEvent( Keyboard.Escape, ( uint kc ) { currentState = EngineState.Quit; } );
        Input.addKeyDownEvent( Keyboard.F5, ( uint kc ) { currentState = EngineState.Reset; } );
        Input.addKeyDownEvent( Keyboard.MouseLeft, ( kc ) { if( auto obj = Input.mouseObject ) logInfo( "Clicked on ", obj.name ); } );

        activeScene = new shared Scene;
        activeScene.loadObjects( "" );
        activeScene.camera = activeScene[ "TestCamera" ].camera;

        uint w, h;
        w = Config.get!uint( "Display.Width" );
        h = Config.get!uint( "Display.Height" );

        //scheduleTimedTask( { logInfo( "Executing: ", Time.totalTime ); }, 250.msecs );
    }

    override void onUpdate()
    {
        //ui.update();
    }
    
    override void onDraw()
    {
        //ui.draw();
    }

    override void onShutdown()
    {
        logInfo( "Shutting down..." );
        foreach( obj; activeScene.objects )
            obj.shutdown();
        activeScene.clear();
        activeScene = null;
    }

    override void onSaveState()
    {
        logInfo( "Resetting..." );
    }
}
