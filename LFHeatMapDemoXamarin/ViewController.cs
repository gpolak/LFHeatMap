using System;
using CoreGraphics;
using CoreLocation;
using Foundation;
using MapKit;
using UIKit;

namespace heatmap
{
	public partial class ViewController : UIViewController
	{
		MKMapView _mapView;
		UIImageView _imageView;
		UISlider _slider;
		CLLocation[] _locations;
		double[] _weights;

		protected ViewController(IntPtr handle) : base(handle)
		{
		}

		public override void ViewDidLoad()
		{
			LoadQuakeData(out _locations, out _weights);
			LoadMapUI();

			base.ViewDidLoad();
		}

		static void LoadQuakeData(out CLLocation[] locations, out double[] weights)
		{
			var data = NSBundle.MainBundle.PathForResource("quake", "plist");
			NSArray quakeData = NSArray.FromFile(data);

			locations = new CLLocation[quakeData.Count];
			weights = new double[quakeData.Count];
			for (uint i = 0; i < quakeData.Count; i++)
			{
				NSDictionary dic = quakeData.GetItem<NSDictionary>(i);

				var latitude = (NSNumber)dic.ObjectForKey(new NSString("latitude"));
				var longitude = (NSNumber)dic.ObjectForKey(new NSString("longitude"));
				var magnitude = ((NSNumber)dic.ObjectForKey(new NSString("magnitude")));
				var location = new CLLocation(latitude.DoubleValue, longitude.DoubleValue);
				locations[i] = location;
				weights[i] = magnitude.DoubleValue * 10;
			}
		}

		void LoadMapUI()
		{
			var rect = View.Bounds;
			_mapView = new MKMapView(rect);
			Add(_mapView);

			_slider = new UISlider(new CGRect(20, rect.Height - 100, rect.Width - 40, 100)) { Value = 0.5F };
			Add(_slider);

			var span = new MKCoordinateSpan(10.0, 13.0);
			var center = new CLLocationCoordinate2D(39.0, -77.0);
			_mapView.Region = new MKCoordinateRegion(center, span);

			_imageView = new UIImageView(_mapView.Frame);
			_imageView.ContentMode = UIViewContentMode.Center;
			Add(_imageView);

			_slider.ValueChanged += SliderValueChanged;
			SliderValueChanged(_slider, null);
		}

		void SliderValueChanged(object sender, EventArgs e)
		{
			float boost = _slider.Value;
			_imageView.Image = LFHeatMap.iOS.HeatMap.HeatMapForMapView(_mapView, boost, _locations, _weights);
		}

		public override void DidReceiveMemoryWarning()
		{
			base.DidReceiveMemoryWarning();
		}
	}
}

