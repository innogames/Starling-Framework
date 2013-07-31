// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.utils
{
	import avm2.intrinsics.memory.lf32;
	import avm2.intrinsics.memory.sf32;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.ApplicationDomain;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import starling.animation.Juggler;
	import starling.core.Starling;
	
	/** The VertexData class manages a raw list of vertex information, allowing direct upload
	 *  to Stage3D vertex buffers. <em>You only have to work with this class if you create display
	 *  objects with a custom render function. If you don't plan to do that, you can safely
	 *  ignore it.</em>
	 *
	 *  <p>To render objects with Stage3D, you have to organize vertex data in so-called
	 *  vertex buffers. Those buffers reside in graphics memory and can be accessed very
	 *  efficiently by the GPU. Before you can move data into vertex buffers, you have to
	 *  set it up in conventional memory - that is, in a Vector object. The vector contains
	 *  all vertex information (the coordinates, color, and texture coordinates) - one
	 *  vertex after the other.</p>
	 *
	 *  <p>To simplify creating and working with such a bulky list, the VertexData class was
	 *  created. It contains methods to specify and modify vertex data. The raw Vector managed
	 *  by the class can then easily be uploaded to a vertex buffer.</p>
	 *
	 *  <strong>Premultiplied Alpha</strong>
	 *
	 *  <p>The color values of the "BitmapData" object contain premultiplied alpha values, which
	 *  means that the <code>rgb</code> values were multiplied with the <code>alpha</code> value
	 *  before saving them. Since textures are created from bitmap data, they contain the values in
	 *  the same style. On rendering, it makes a difference in which way the alpha value is saved;
	 *  for that reason, the VertexData class mimics this behavior. You can choose how the alpha
	 *  values should be handled via the <code>premultipliedAlpha</code> property.</p>
	 *
	 */
	public class VertexData
	{
		/** The total number of elements (Numbers) stored per vertex. */
		public static const ELEMENTS_PER_VERTEX:int = 8;
		
		/** The offset of position data (x, y) within a vertex. */
		public static const POSITION_OFFSET:int = 0;
		
		/** The offset of color data (r, g, b, a) within a vertex. */
		public static const COLOR_OFFSET:int = 2;
		
		/** The offset of texture coordinate (u, v) within a vertex. */
		public static const TEXCOORD_OFFSET:int = 6;
		
		private var mRawData:ByteArray;
		private var mPremultipliedAlpha:Boolean;
		private var mNumVertices:int;
		
		/** Helper object. */
		private static var sHelperPoint:Point = new Point();
		
		public static var vertexDataInDomainMemory:VertexData;
		
		/** Create a new VertexData object with a specified number of vertices. */
		public function VertexData(numVertices:int, premultipliedAlpha:Boolean = false)
		{
			mRawData = new ByteArray;
			mRawData.endian = Endian.LITTLE_ENDIAN;
			mRawData.length = ApplicationDomain.MIN_DOMAIN_MEMORY_LENGTH;
			mPremultipliedAlpha = premultipliedAlpha;
			this.numVertices = numVertices;
		}
		
		/** Creates a duplicate of either the complete vertex data object, or of a subset.
		 *  To clone all vertices, set 'numVertices' to '-1'. */
		public function clone(vertexID:int = 0, numVertices:int = -1):VertexData
		{
			if (numVertices < 0 || vertexID + numVertices > mNumVertices)
				numVertices = mNumVertices - vertexID;
			
			var clone:VertexData = new VertexData(0, mPremultipliedAlpha);
			clone.mNumVertices = numVertices;
			//clone.mRawData = mRawData.slice(vertexID * ELEMENTS_PER_VERTEX,
			//numVertices * ELEMENTS_PER_VERTEX);
			//clone.mRawData.fixed = true;
			clone.mRawData.position = 0;
			clone.mRawData.writeBytes(mRawData, (vertexID * ELEMENTS_PER_VERTEX) << 2, (numVertices * ELEMENTS_PER_VERTEX) << 2);
			
			clone.mRawData.length = Math.max(clone.mRawData.length, ApplicationDomain.MIN_DOMAIN_MEMORY_LENGTH);
			return clone;
		}
		
		/** Copies the vertex data (or a range of it, defined by 'vertexID' and 'numVertices')
		 *  of this instance to another vertex data object, starting at a certain index. */
		public function copyTo(targetData:VertexData, targetVertexID:int = 0, vertexID:int = 0, numVertices:int = -1):void
		{
			if (numVertices < 0 || vertexID + numVertices > mNumVertices)
				numVertices = mNumVertices - vertexID;
			
			// todo: check/convert pma
			
			var targetRawData:ByteArray = targetData.mRawData;
			var targetIndex:int = targetVertexID * ELEMENTS_PER_VERTEX * 4;
			var sourceIndex:int = vertexID * ELEMENTS_PER_VERTEX * 4;
			var dataLength:int = numVertices * ELEMENTS_PER_VERTEX * 4;
			
			//for (var i:int=sourceIndex; i<dataLength; ++i)
			//targetRawData[int(targetIndex++)] = mRawData[i];
			
			targetRawData.position = targetIndex;
			targetRawData.writeBytes(mRawData, sourceIndex, dataLength);
			//if (targetRawData.length < ApplicationDomain.MIN_DOMAIN_MEMORY_LENGTH)
				//targetRawData.length = ApplicationDomain.MIN_DOMAIN_MEMORY_LENGTH;
		}
		
		/** Appends the vertices from another VertexData object. */
		public function append(data:VertexData):void
		{
			//mRawData.fixed = false;
			
			var targetIndex:int = numVertices * ELEMENTS_PER_VERTEX;
			var rawData:ByteArray = data.mRawData;
			var rawDataLength:int = data.numVertices * ELEMENTS_PER_VERTEX;
			
			//for (var i:int=0; i<rawDataLength; ++i)
			//mRawData[int(targetIndex++)] = rawData[i];
			
			mRawData.position = targetIndex << 2;
			mRawData.writeBytes(rawData, 0, rawDataLength << 2);
			mRawData.length = Math.max(mRawData.length, ApplicationDomain.MIN_DOMAIN_MEMORY_LENGTH);
			
			mNumVertices += data.numVertices;
			//mRawData.fixed = true;
		}

        // functions

        /** Updates the position values of a vertex. */
        public function setPosition(vertexID:int, x:Number, y:Number):void
        {
            var offset:int = getOffset(vertexID) + POSITION_OFFSET;
			mRawData.position = offset << 2;
			mRawData.writeFloat(x);
			mRawData.writeFloat(y);
            //mRawData[offset] = x;
            //mRawData[int(offset+1)] = y;
        }

        /** Returns the position of a vertex. */
		[Inline]
        final public function getPosition(vertexID:int, position:Point):void
        {
            var offset:int = getOffset(vertexID) + POSITION_OFFSET;
			mRawData.position = offset << 2;
            position.x = mRawData.readFloat();
            position.y = mRawData.readFloat();
            //position.x = mRawData[offset];
            //position.y = mRawData[int(offset+1)];
        }
		
        /** Updates the RGB color values of a vertex. */
        public function setColor(vertexID:int, color:uint):void
        {
			switchDomainMemory()
			__setColor(vertexID, color);
			/*
            var offset:int = getOffset(vertexID) + COLOR_OFFSET;
			if (mPremultipliedAlpha)
			{
				mRawData.position = (offset + 3) << 2;
				var multiplier:Number = mRawData.readFloat();
			}
			else
			{
				multiplier = 1.0;
			}
			mRawData.position = offset << 2;
			mRawData.writeFloat( ((color >> 16) & 0xff) / 255.0 * multiplier );
			mRawData.writeFloat( ((color >>  8) & 0xff) / 255.0 * multiplier );
			mRawData.writeFloat( ( color        & 0xff) / 255.0 * multiplier );
            //mRawData[offset]        = ((color >> 16) & 0xff) / 255.0 * multiplier;
            //mRawData[int(offset+1)] = ((color >>  8) & 0xff) / 255.0 * multiplier;
            //mRawData[int(offset+2)] = ( color        & 0xff) / 255.0 * multiplier;
			*/
        }
		
		/** Updates the RGB color values of a vertex. */
		private function __setColor(vertexID:int, color:uint):void
		{
			var offset:int = getOffset(vertexID) + COLOR_OFFSET;
			//checkDomainMemory();
			offset <<= 2;
			//var multiplier:Number = mPremultipliedAlpha ? mRawData[int(offset+3)] : 1.0;
			var multiplier:Number = mPremultipliedAlpha ? lf32(offset + 12) : 1.0;
			sf32(((color >> 16) & 0xff) / 255.0 * multiplier, offset);
			sf32(((color >> 8) & 0xff) / 255.0 * multiplier, offset + 4);
			sf32((color & 0xff) / 255.0 * multiplier, offset + 8);
			//mRawData[offset]        = ((color >> 16) & 0xff) / 255.0 * multiplier;
			//mRawData[int(offset+1)] = ((color >>  8) & 0xff) / 255.0 * multiplier;
			//mRawData[int(offset+2)] = ( color        & 0xff) / 255.0 * multiplier;
		}
		
        /** Returns the RGB color of a vertex (no alpha). */
        final public function getColor(vertexID:int):uint
        {
			switchDomainMemory()
			return __getColor(vertexID);
            /*var offset:int = getOffset(vertexID) + COLOR_OFFSET;
			
			//var divisor:Number = mPremultipliedAlpha ? mRawData[int(offset+3)] : 1.0;
			if (mPremultipliedAlpha)
			{
				mRawData.position = (offset + 3) << 2;
				var divisor:Number = mRawData.readFloat();
			}
			else
			{
				divisor = 1.0;
			}

            if (divisor == 0) return 0;
            else
            {
				mRawData.position = offset << 2;
                var red:Number   = mRawData.readFloat() / divisor;
                var green:Number = mRawData.readFloat() / divisor;
                var blue:Number  = mRawData.readFloat() / divisor;

                return (int(red*255) << 16) | (int(green*255) << 8) | int(blue*255);
            }*/
        }
		
		/** Returns the RGB color of a vertex (no alpha). */
		final private function __getColor(vertexID:int):uint
		{
			var offset:int = getOffset(vertexID) + COLOR_OFFSET;
			//checkDomainMemory();
			offset <<= 2;
			//var divisor:Number = mPremultipliedAlpha ? mRawData[int(offset+3)] : 1.0;
			var divisor:Number = mPremultipliedAlpha ? lf32(offset + 12) : 1.0;
			
			if (divisor == 0)
				return 0;
			else
			{
				var red:Number = lf32(offset) / divisor;
				var green:Number = lf32(offset + 4) / divisor;
				var blue:Number = lf32(offset + 8) / divisor;
				//var red:Number   = mRawData[offset]        / divisor;
				//var green:Number = mRawData[int(offset+1)] / divisor;
				//var blue:Number  = mRawData[int(offset+2)] / divisor;
				
				return (int(red * 255) << 16) | (int(green * 255) << 8) | int(blue * 255);
			}
		}
		
        /** Updates the alpha value of a vertex (range 0-1). */
        final public function setAlpha(vertexID:int, alpha:Number):void
        {
            var offset:int = getOffset(vertexID) + COLOR_OFFSET + 3;
			
            if (mPremultipliedAlpha)
            {
                if (alpha < 0.001) alpha = 0.001; // zero alpha would wipe out all color data
                var color:uint = getColor(vertexID);
                mRawData.position = offset << 2;
				mRawData.writeFloat(alpha);
                setColor(vertexID, color);
            }
            else
            {
                mRawData.position = offset << 2;
				mRawData.writeFloat(alpha);
            }
        }

		/** Updates the alpha value of a vertex (range 0-1). */
		final private function __setAlpha(vertexID:int, alpha:Number):void
		{
			var offset:int = getOffset(vertexID) + COLOR_OFFSET + 3;
			offset <<= 2;
			
			if (mPremultipliedAlpha)
			{
				if (alpha < 0.001)
					alpha = 0.001; // zero alpha would wipe out all color data
				var color:uint = __getColor(vertexID);
				sf32(alpha, offset);
				__setColor(vertexID, color);
			}
			else
			{
				sf32(alpha, offset);
			}
		}
		
		/** Returns the alpha value of a vertex in the range 0-1. */
		final public function getAlpha(vertexID:int):Number
        {
            var offset:int = getOffset(vertexID) + COLOR_OFFSET + 3;
			mRawData.position = offset << 2;
            return mRawData.readFloat();
        }
		
		/** Returns the alpha value of a vertex in the range 0-1. */
		final private function __getAlpha(vertexID:int):Number
		{
			var offset:int = getOffset(vertexID) + COLOR_OFFSET + 3;
			//checkDomainMemory();
			return lf32(offset << 2);
		}
		
		/** Updates the texture coordinates of a vertex (range 0-1). */
		final public function setTexCoords(vertexID:int, u:Number, v:Number):void
		{
			var offset:int = getOffset(vertexID) + TEXCOORD_OFFSET;
			switchDomainMemory()
			offset <<= 2;
			sf32(u, offset);
			sf32(v, offset + 4);
		}
		
		/** Returns the texture coordinates of a vertex in the range 0-1. */
		final public function getTexCoords(vertexID:int, texCoords:Point):void
		{
			var offset:int = getOffset(vertexID) + TEXCOORD_OFFSET;
			switchDomainMemory()
			offset <<= 2;
			texCoords.x = lf32(offset);
			texCoords.y = lf32(offset + 4);
		}
		
		// utility functions
		
		/** Translate the position of a vertex by a certain offset. */
		final public function translateVertex(vertexID:int, deltaX:Number, deltaY:Number):void
        {
            var offset:int = getOffset(vertexID) + POSITION_OFFSET;
			offset <<= 2;
			mRawData.position = offset;
			var x:Number			= mRawData.readFloat();
			var y:Number			= mRawData.readFloat();
			mRawData.position = offset;
			mRawData.writeFloat(x+deltaX);
			mRawData.writeFloat(y+deltaY);
        }
		
		/** Transforms the position of subsequent vertices by multiplication with a
		 *  transformation matrix. */
		final public function transformVertex(vertexID:int, matrix:Matrix, numVertices:int = 1):void
		{
			var offset:int = getOffset(vertexID) + POSITION_OFFSET;
			switchDomainMemory()
			offset <<= 2;
			var inc:int = ELEMENTS_PER_VERTEX << 2;
			for (var i:int = 0; i < numVertices; ++i)
			{
				var x:Number = lf32(offset);
				var y:Number = lf32(offset + 4);
				
				var a:Number = matrix.a * x + matrix.c * y + matrix.tx;
				var b:Number = matrix.d * y + matrix.b * x + matrix.ty;
				
				sf32(a, offset);
				sf32(b, offset + 4);
				
				offset += inc;
			}
		}
		
		/** Sets all vertices of the object to the same color values. */
		final public function setUniformColor(color:uint):void
		{
			switchDomainMemory()
			for (var i:int = 0; i < mNumVertices; ++i)
				__setColor(i, color);
		}
		
		/** Sets all vertices of the object to the same alpha values. */
		final public function setUniformAlpha(alpha:Number):void
		{
			switchDomainMemory()
			for (var i:int = 0; i < mNumVertices; ++i)
				__setAlpha(i, alpha);
		}
		
		/** Multiplies the alpha value of subsequent vertices with a certain delta. */
		final public function scaleAlpha(vertexID:int, alpha:Number, numVertices:int = 1):void
		{
			if (alpha == 1.0)
				return;
			if (numVertices < 0 || vertexID + numVertices > mNumVertices)
				numVertices = mNumVertices - vertexID;
			
			var i:int;
			switchDomainMemory()
			if (mPremultipliedAlpha)
			{
				for (i = 0; i < numVertices; ++i)
					__setAlpha(vertexID + i, __getAlpha(vertexID + i) * alpha);
			}
			else
			{
				var offset:int = getOffset(vertexID) + COLOR_OFFSET + 3;
				offset <<= 2;
				var inc:int = ELEMENTS_PER_VERTEX << 2;
				for (i = 0; i < numVertices; ++i)
				{
					var value:Number = lf32(offset);
					sf32(alpha * value, offset);
					
					offset += inc;
				}
			}
		}
		[Inline]
		private final function getOffset(vertexID:int):int
		{
			return vertexID * ELEMENTS_PER_VERTEX;
		}
		
		/** Calculates the bounds of the vertices, which are optionally transformed by a matrix.
		 *  If you pass a 'resultRect', the result will be stored in this rectangle
		 *  instead of creating a new object. To use all vertices for the calculation, set
		 *  'numVertices' to '-1'. */
		public function getBounds(transformationMatrix:Matrix=null,
                                  vertexID:int=0, numVertices:int=-1,
                                  resultRect:Rectangle = null):Rectangle
		{
			if (resultRect == null) resultRect = new Rectangle();
            if (numVertices < 0 || vertexID + numVertices > mNumVertices)
                numVertices = mNumVertices - vertexID;
			
			var minX:Number = Number.MAX_VALUE, maxX:Number = -Number.MAX_VALUE;
			var minY:Number = Number.MAX_VALUE, maxY:Number = -Number.MAX_VALUE;
			var offset:int = getOffset(vertexID) + POSITION_OFFSET;
			switchDomainMemory()
			offset <<= 2;
			var x:Number, y:Number, i:int;
			
			var inc:int = ELEMENTS_PER_VERTEX << 2;
			if (transformationMatrix == null)
			{
				for (i = vertexID; i < numVertices; ++i)
				{
					x = lf32(offset);
					y = lf32(offset + 4);
					offset += inc;
					
					minX = minX < x ? minX : x;
					maxX = maxX > x ? maxX : x;
					minY = minY < y ? minY : y;
					maxY = maxY > y ? maxY : y;
				}
			}
			else
			{
				for (i = vertexID; i < numVertices; ++i)
				{
					x = lf32(offset);
					y = lf32(offset + 4);
					offset += inc;
					
					MatrixUtil.transformCoords(transformationMatrix, x, y, sHelperPoint);
					minX = minX < sHelperPoint.x ? minX : sHelperPoint.x;
					maxX = maxX > sHelperPoint.x ? maxX : sHelperPoint.x;
					minY = minY < sHelperPoint.y ? minY : sHelperPoint.y;
					maxY = maxY > sHelperPoint.y ? maxY : sHelperPoint.y;
				}
			}
			
			resultRect.setTo(minX, minY, maxX - minX, maxY - minY);
			return resultRect;
		}
		
		// properties
		
		/** Indicates if any vertices have a non-white color or are not fully opaque. */
		public function get tinted():Boolean
		{
			var offset:int = COLOR_OFFSET;
			switchDomainMemory()
			offset <<= 2;
			var inc:int = ELEMENTS_PER_VERTEX << 2;
			for (var i:int = 0; i < mNumVertices; ++i)
			{
				for (var j:int = 0; j < 16; j += 4)
					if (lf32(offset + j) != 1.0)
						return true;
				
				offset += inc;
			}
			
			return false;
		}
		
		/** Changes the way alpha and color values are stored. Updates all exisiting vertices. */
		public function setPremultipliedAlpha(value:Boolean, updateData:Boolean = true):void
		{
			if (value == mPremultipliedAlpha)
				return;
			
			if (updateData)
			{
				var dataLength:int = mNumVertices * ELEMENTS_PER_VERTEX;
				
				switchDomainMemory()
				for (var i:int = COLOR_OFFSET; i < dataLength; i += ELEMENTS_PER_VERTEX)
				{
					var offset:int = i << 2;
					var alpha:Number = lf32(offset + 12);
					var divisor:Number = mPremultipliedAlpha ? alpha : 1.0;
					var multiplier:Number = value ? alpha : 1.0;
					
					if (divisor != 0)
					{
						var r:Number = lf32(offset);
						var g:Number = lf32(offset + 4);
						var b:Number = lf32(offset + 8);
						sf32(r / divisor * multiplier, offset);
						sf32(g / divisor * multiplier, offset + 4);
						sf32(b / divisor * multiplier, offset + 8);
					}
				}
			}
			
			mPremultipliedAlpha = value;
		}
		
		public function dispose():void
		{
			if (mRawData)
			{
				mRawData.clear();
				mRawData = null;
			}
		}
		
		/** Indicates if the rgb values are stored premultiplied with the alpha value. */
		final public function get premultipliedAlpha():Boolean
		{
			return mPremultipliedAlpha;
		}
		
		/** The total number of vertices. */
		final public function get numVertices():int
		{
			return mNumVertices;
		}
		
		public function set numVertices(value:int):void
		{
			//mRawData.fixed = false;
			
			var i:int;
			var delta:int = value - mNumVertices;
			
			if (delta > 0)
			{
				var offset:int = mNumVertices * ELEMENTS_PER_VERTEX;
				mRawData.length = Math.max(mRawData.length, value * ELEMENTS_PER_VERTEX * 4);
				switchDomainMemory();
				offset += 5;
				offset <<= 2;
				
				var inc:int = ELEMENTS_PER_VERTEX << 2;
				for (i = 0; i < delta; ++i)
				{
					sf32(1.0, offset);
					offset += inc
						//mRawData.push(0, 0,  0, 0, 0, 1,  0, 0); // alpha should be '1' per default
				}
			}
			
			//mRawData.length = (value * ELEMENTS_PER_VERTEX) << 2;
			//for (i=0; i<-(delta*ELEMENTS_PER_VERTEX); ++i)
			//mRawData.pop();
			
			mNumVertices = value;
			//mRawData.fixed = true;
		}
		[Inline]
		private final function switchDomainMemory():void
		{
			if (vertexDataInDomainMemory != this)
			{
				vertexDataInDomainMemory = this;
				ApplicationDomain.currentDomain.domainMemory = mRawData;
			}
		}
		
		/** The raw vertex data; not a copy! */
		final public function get rawData():ByteArray
		{
			return mRawData;
		}
	}
}