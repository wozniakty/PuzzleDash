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


        int[] hor = [ 5, 6 ];
        int[]*[int] matchSet;
        int[] matchr;
        int[]* match = &matchr;

        foreach( index; hor )
        {
            (*match) ~= index;
            matchSet[index] = match;
        }

        logDebug( *(matchSet[5]) );
        //logDebug( matchSet );
        //logDebug( matchSet2 );
        //logDebug( thing2 );

        int[] a = [ 1, 2, 3 ];
        int[]* ap = &a;
        int[]* ap2 = ap;
        //logDebug( "b1: ", b );
        a[1] = 8;
        //logDebug( *ap2 );
        //logDebug( "b2: ", b );
        a ~= 9;
        //logDebug( *ap2 );
        //logDebug( "a: ", a );
        //logDebug( "b3: ", b );
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
