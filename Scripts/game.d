module game;
import grid;
import core, graphics, components, utility;

class Game : DGame
{
    Camera cam;
    
    override void onInitialize()
    {

        logInfo( "Initializing TestGame..." );

        Input.addKeyDownEvent( Keyboard.Delete, ( uint kc ) { currentState = EngineState.Quit; } );

        activeScene = new Scene;
        activeScene.loadObjects( "" );
        activeScene.camera = activeScene[ "TestCamera" ].camera;
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
