﻿/********************************************************************** Copyright (c) 2009 Scaleform Corporation. All Rights Reserved. Licensees may use this file in accordance with the valid Scaleform License Agreement provided with the software. This file is provided  AS IS with NO WARRANTY OF ANY KIND, INCLUDING THE WARRANTY OF DESIGN,  MERCHANTABILITY AND FITNESS FOR ANY PURPOSE.**********************************************************************//** * The UIComponent is the basis for all components in the Scaleform framework. It contains functionality found in all components such as initialization, focus management, invalidation, sizing, and events. * * @see "Extending Components in the User Guide" */ /**/import flash.geom.Rectangle;import gfx.events.EventDispatcher;import gfx.managers.FocusHandler;import gfx.managers.InputDelegate;import gfx.motion.Tween;import gfx.ui.InputDetails;import gfx.utils.Delegate;import mx.transitions.easing.Strong;[InspectableList("disabled", "visible")]class gfx.core.UIComponent extends MovieClip {	// Constants:// Public Properties:	/** The container or related component that should receive actual focus when this component is given focus. */	public var focusTarget:Object; // MovieClip or TextField	/** Indicates if the component has been complete loaded. */	public var initialized:Boolean = false;	// Private Properties:	private var invalidationIntervalID:Number;	private var __width:Number = 0;	private var __height:Number = 0;	private var _disabled:Boolean = false	private var _focused:Boolean = false;	private var _displayFocus:Boolean = false;	private var focusHandlerReference:FocusHandler; // Force the inclusion of the focusHandler.	private var sizeIsInvalid:Boolean = false; // The size has changed, and needs to be redrawn.	// EventDispatcher mix-in	/** Mixed in from {@link EventDispatcher#addEventListener EventDispatcher} */	public var addEventListener:Function;		/** Mixed in from {@link EventDispatcher#removeEventListener EventDispatcher} */ 	public var removeEventListener:Function;	/** Mixed in from {@link EventDispatcher#hasEventListener EventDispatcher} */	public var hasEventListener:Function;	/** Mixed in from {@link EventDispatcher#removeAllEventListeners EventDispatcher} */	public var removeAllEventListeners:Function;		/** Mixed in from {@link EventDispatcher#cleanUpEvents EventDispatcher} */	private var cleanUpEvents:Function;	/** Mixed in from {@link EventDispatcher#dispatchEvent EventDispatcher} */	private var dispatchEvent:Function;	// UI Elements:	//private var focusCapture:MovieClip;// Initialization:	/**	 * The constructor is called when a UIComponent or a sub-class of UIComponent is instatiated on stage or by using {@code attachMovie()} in ActionScript. This component can <b>not</b> be instantiated using {@code new} syntax. When creating new components that extend UIComponent, ensure that a {@code super()} call is made first in the constructor.	 */	private function UIComponent() {		EventDispatcher.initialize(this);		Tween.init();	}		private function onLoad():Void {		if (__width == 0) { // Only set this if it has not been set already.			setSize(_width, _height);		}		initialized = true;				configUI();		validateNow();				// InputDelegate will not instantiate unless a component is clicked. This forces it to.		// Additionally, there is no focusBoundary if selected is set before initialization is complete.		if (_focused && Selection.getFocus() == null) { FocusHandler.instance.onSetFocus(null, this); }			}	// Public Methods:	/**	 * Enables or disables the component.  Disabled components should not receive mouse, keyboard, or any other kind of focus or interaction. Note that "disabled" is used in place of "enabled" to because "enabled" can not be overridden.	 */	[Inspectable(defaultValue="false", verbose="1")]	public function get disabled():Boolean { return _disabled; }	public function set disabled(value:Boolean):Void {		_disabled = value;		super.enabled = !value;		useHandCursor = !value;		invalidate();	}		/**	 * Show or hide the component. Allows the {@code _visible} property to be overridden, and dispatch a "show" or "hide" event.	 */	[Inspectable(defaultValue="true", verbose="1")]	public function get visible():Boolean { return _visible; }	public function set visible(value:Boolean):Void {		if (_visible == value) { return; }		_visible = value;		var eventType:String = value ? "show" : "hide";		dispatchEvent({type:eventType});	}		/**	 * Gets and sets the width of the component using internal sizing mechanisms. Use this instead of {@code _width}.  Use {@link setSize()} to set both the width and the height at the same time.	 */	public function get width():Number { return __width; }	public function set width(value:Number):Void {		setSize(value, __height || _height);	}	/**	 * Gets and sets the height of the component using internal sizing mechanisms. Use this instead of {@code _height}.  Use {@link setSize()} to set both the width and the height at the same time.	 */	public function get height():Number { return __height; }	public function set height(value:Number):Void {		setSize(__width || _width, value);	}	/**	 * Sets the width and height of the component at the same time using internal sizing mechanisms.	 * @param width The new width of the component.	 * @param height The new height of the component.	 */	public function setSize(width:Number, height:Number):Void {		if (__width == width && __height == height) { return; }		__width = width;		__height = height;		sizeIsInvalid = true;		invalidate();	}		/**	 * Get and set the focus of the component.  This property is explicitly called by the FocusHandler When the stage or application focus is given to this component, but can also be set manually on the component to set or clear focus.  Currently, an application can have only a single focus. When the focus on a component changes, a "focusIn" or "focusOut" event is fired.	 */	public function get focused():Boolean { return _focused; }	public function set focused(value:Boolean):Void {		if (value == _focused) { return; }		_focused = value;		if (!value && Selection.getFocus() == this) {			Selection.setFocus(null);		} else if (value && Selection.getFocus() != this) {			Selection.setFocus(this);		}		changeFocus();				// Dispatch a focus change event		var eventType:String = value ? "focusIn" : "focusOut";		dispatchEvent({type:eventType});	}		/**	 * Set the component to display itself as focused, even if it is not.  This property is used by container components to make them appear focused.	 */	public function get displayFocus():Boolean { return _displayFocus; }	public function set displayFocus(value:Boolean):Void {		if (value == _displayFocus) { return; }		_displayFocus = value;		changeFocus();	}		/**	 * Handle input from the game, via controllers or keyboard. The default handleInput will handle standalone and composite components.	 * @param details An {@code InputDetails} object containing details from the interaction.	 * @param pathToFocus A list of children in the focus path that are below this component. Components are responsible for calling {@code handleInput()} on the next component in the {@code pathToFocus} unless they choose to intercept the call.	 * @returns A Boolean value specifying if the focus was handled or not by this component or sub-components. This suggests to components higher up in the focus path that they should not also handle the input.	 * @see gfx.managers.FocusHandler FocusHandler	 * @see gfx.ui.InputDetails InputDetails	 */	public function handleInput(details:InputDetails, pathToFocus:Array):Boolean { 		if (pathToFocus != null && pathToFocus.length > 0) {			var handled:Boolean = pathToFocus[0].handleInput(details, pathToFocus.slice(1));			if (handled) { return handled; }		}		return false; 	}		/**	 * 显示	 */	public function show() {		this["onTweenComplete"] = null;		delete this["onTweenComplete"];		this.visible = true;		this["tweenTo"](0.5, { _alpha:100 }, Strong.easeOut);	}		/**	 * 隐藏	 */	public function hide() {		this["onTweenComplete"] = null;		delete this["onTweenComplete"];        this["tweenTo"](0.5, { _alpha:0 }, Strong.easeOut);				this["onTweenComplete"] = Delegate.create(this, function() {			this.visible = false;			this.removeMovieClip();			UIComponent["_instance"] = null;			UIComponent["instance"] = null;			delete UIComponent["_instance"];			delete UIComponent["instance"];	   	})	}		/**	 * An internal property of the component has changed, requiring a redraw.  The invalidation mechanism lets components trigger multiple redraw commands at the same time, resulting in only a single redraw. the {@code invalidate()} method is public so that it can be called externally.	 */	public function invalidate():Void {		if (invalidationIntervalID) { return; }		invalidationIntervalID = setInterval(this, "validateNow", 1); // enterFrames collide with component behaviours	}		/**	 * When the component has been invalidated, this method is called which validates the component, and redraws the component immediately by calling {@code draw()}. The {@code validateNow()} method is public so that it can be called externally.	 */	public function validateNow():Void {		if (invalidationIntervalID == null) { return; }		clearInterval(invalidationIntervalID);		delete(invalidationIntervalID);				draw();		sizeIsInvalid = false;	}				/** @exclude */	public function toString():String {		return "[Scaleform UIComponent " + _name + "]";	}	// Private Methods:	/**	 * Configure the interface when the component is initialized.  Use this method to set up sub-components, listeners, etc.	 */	private function configUI():Void {}		/**	 * Reset the scale of the component, and call {@code setSize()} with the initial component dimensions. Composite components such as ScrollBar can use this method to reset the scale of a component resized on the stage, and then reflow the sub-components to fit the new size. Usually called in the {@code configUI()} method before the first draw.	 */	private function initSize():Void {		var w:Number = __width == 0 ? _width : __width;		var h:Number = __height == 0 ? _height : __height;		_xscale = _yscale = 100;		setSize(w,h);	}		/**	 * Draw the component after it has been invalidated. Use this method to reflow component size and position, redraw data, etc.  When appropriate, ensure that a call to {@code super.draw()} is made when extending a component and overriding this method.	 */	private function draw():Void {}		/**	 * Called after focus has been given or taken from the component. Use this method to change the appearance or behavior of the component when the focus changes.	 */	private function changeFocus():Void {}		// Use the hitTest instead of the target, in case the target is nested (which it will almost always be).	private function onMouseWheel(delta:Number, target:Object):Void {		if (visible && hitTest(_root._xmouse, _root._ymouse, true)) {			scrollWheel(delta > 0 ? 1 : -1);		}	}	private function scrollWheel(delta:Number):Void {}	}