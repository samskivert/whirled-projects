﻿package org.papervision3d.objects.parsers {
	
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.net.URLStream;
	import flash.utils.ByteArray;
	
	import nochump.util.zip.ZipEntry;
	import nochump.util.zip.ZipFile;
	
	import org.papervision3d.materials.BitmapMaterial;
	import org.papervision3d.materials.utils.MaterialsList;
	import org.papervision3d.objects.DisplayObject3D;
	
	public class Sketchup extends DisplayObject3D {
		public  var model:SketchupCollada
		private var allMaterials:MaterialsList = new MaterialsList();
		
		private var count:Number = 1;
		private var COLLADA:XML;
		private var totalMaterials:Number;
		private var initObject:Object = new Object();
		private var _scale:Number = 1; 
		
		public function Sketchup( kmz:String, initObject:* = null) {
			super();
			initObject = initObject;
			var urlStream:URLStream = new URLStream();
				urlStream.addEventListener(Event.COMPLETE, completeHandler);
				urlStream.load(new URLRequest( kmz ));
		};
		
		private function completeHandler(event:Event):void {
			var datastream:URLStream = URLStream(event.target);
			
			var kmzFile:ZipFile = new ZipFile(datastream);
			totalMaterials = kmzFile.entries.join("@").split(".jpg").length;
			for(var i:int = 0; i < kmzFile.entries.length; i++) {
				var entry:ZipEntry = kmzFile.entries[i];
				var data:ByteArray = kmzFile.getInput(entry);
				if(entry.name.indexOf(".dae")>-1 && entry.name.indexOf("models/")>-1) {
					COLLADA = new XML(data.toString());
				} else if((entry.name.indexOf(".jpg")>-1 || entry.name.indexOf(".png")>-1) && entry.name.indexOf("images/")>-1) {
					var _loader : Loader = new Loader();
					_loader.name = entry.name.split("/").reverse()[0].split(".")[0];
					_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadBitmapCompleteHandler);
					_loader.loadBytes(data);
				};	  
			};
			
			
		};
		
		private function loadBitmapCompleteHandler(e:Event):void {
			var loader:Loader = Loader(e.target.loader);
			var bitmap:Bitmap = Bitmap(loader.content);
			var bitmapMaterial:BitmapMaterial = new BitmapMaterial(bitmap.bitmapData);
			bitmapMaterial.tiled = true;
			bitmapMaterial.name = e.target.loader.name;
			bitmapMaterial.oneSide = false;
			allMaterials.addMaterial( bitmapMaterial, e.target.loader.name );
			count++;
			trace("Loaded "+count+" of "+totalMaterials+" materials")
			if(count == totalMaterials) build();
		};
		
		private function build():void {
			model = new SketchupCollada(COLLADA, allMaterials, _scale, initObject);
			for(var o:* in initObject) {
				model[o] = initObject[o];
			};
			this.addChild(model);
		};
		
	};
};