using System;
using System.Collections.Generic;
using System.Drawing;
using CoreGraphics;
using CoreLocation;
using MapKit;
using UIKit;

namespace LFHeatMap.iOS
{
	public static class HeatMap
	{
		public static UIImage HeatMapForMapView(MKMapView mapView, double boost, CLLocation[] locations, double[] weights)
		{
			if (mapView == null || locations == null)
				return null;

			var points = new List<PointF>();

			for (int i = 0; i < locations.Length; i++)
			{
				CGPoint point = mapView.ConvertCoordinate(locations[i].Coordinate, mapView);
				points.Add(new PointF((float)point.X, (float)point.Y));
			}

			return HeatMapWithRect(mapView.Frame, boost, points.ToArray(), weights);
		}

		public static UIImage HeatMapWithRect(CGRect rect, double boost, PointF[] points, double[] weights)
		{
			return HeatMapWithRect(rect, boost, points, weights, false, true);
		}

		public static UIImage HeatMapWithRect(CGRect rect, double boost, PointF[] points, double[] weights, bool weightsAdjustmentEnabled, bool groupingEnabled)
		{
			var rect1 = new Rect { Width = rect.Width, Height = rect.Height, X = rect.X, Y = rect.Y };

			var points1 = new List<PointWithWeight>();
			for (int i = 0; i < points.Length; i++)
			{
				points1.Add(new PointWithWeight(points[i].X, points[i].Y, weights[i]));
			}
			var bytes = LFHeatMap.HeatMap.HeatMapForRectangle(rect1, boost, points1.ToArray(), weightsAdjustmentEnabled, groupingEnabled);

			CGImage cgImage = null;
			using (var colorSpace = CGColorSpace.CreateDeviceRGB())
			using (var context = new CGBitmapContext(bytes, (nint)rect.Width, (nint)rect.Height, 8, 4 * (nint)rect.Width, colorSpace, CGBitmapFlags.PremultipliedLast | CGBitmapFlags.ByteOrderDefault))
				cgImage = context.ToImage();

			return new UIImage(cgImage);
		}


		public static UIImage HeatMapWithRect(CGRect rect, double boost, PointWithWeight[] points, bool weightsAdjustmentEnabled, bool groupingEnabled)
		{
			var rect1 = new Rect { Width = rect.Width, Height = rect.Height, X = rect.X, Y = rect.Y };

			var bytes = LFHeatMap.HeatMap.HeatMapForRectangle(rect1, boost, points, weightsAdjustmentEnabled, groupingEnabled);

			CGImage cgImage = null;
			using (var colorSpace = CGColorSpace.CreateDeviceRGB())
			using (var context = new CGBitmapContext(bytes, (nint)rect.Width, (nint)rect.Height, 8, 4 * (nint)rect.Width, colorSpace, CGBitmapFlags.PremultipliedLast | CGBitmapFlags.ByteOrderDefault))
				cgImage = context.ToImage();

			return new UIImage(cgImage);
		}

	}
}

