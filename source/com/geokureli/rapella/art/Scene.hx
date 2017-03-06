package com.geokureli.rapella.art;

import com.geokureli.rapella.art.ui.InteractMenu;
import com.geokureli.rapella.utils.Game;
import com.geokureli.rapella.utils.SwfUtils;
import openfl.display.MovieClip;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.geom.Rectangle;

/**
 * ...
 * @author George
 */

class Scene extends Wrapper {

    var _cameraBounds:Rectangle;
    var _interactables:Array<Sprite>;

    public function new(target:Sprite) {
        super(target);

        initChildren();
    }

    override function setDefaults() {
        super.setDefaults();

        _isParent = true;
        _cameraBounds = new Rectangle();
    }

    function initChildren() {

        var cameraBoundsMC:MovieClip = SwfUtils.get(_target, 'cameraBounds');
        if (cameraBoundsMC != null)
            _cameraBounds = cameraBoundsMC.getBounds(_target);
        _target.removeChild(cameraBoundsMC);

        initCamera();

        _interactables = SwfUtils.getAll(_target, 'interactable');
        for (interactable in _interactables) {

            interactable.useHandCursor = true;
            interactable.mouseEnabled  = true;
            interactable.mouseChildren = true;
            interactable.addEventListener(MouseEvent.CLICK, onInteract);
        }
    }

    private function onInteract(e:MouseEvent):Void {

        InteractMenu.setTarget(cast e.currentTarget);
    }

    function initCamera() {

        // --- CAMERA BOUNDS CAN'T BE SMALLER THAN THE LEVEL
        if (_cameraBounds.width  < Game.stage.stageWidth)
            _cameraBounds.width  = Game.stage.stageWidth;
        if (_cameraBounds.height < Game.stage.stageHeight)
            _cameraBounds.height = Game.stage.stageHeight;

        Game.camera.bounds.copyFrom(_cameraBounds);
        Game.camera.drawTarget = this;
    }
}
