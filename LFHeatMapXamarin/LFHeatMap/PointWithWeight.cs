namespace LFHeatMap
{
	public struct PointWithWeight
	{

		public PointWithWeight(double x, double y, double weight)
		{
			X = x;
			Y = y;
			Weight = weight;
		}
		public double X
		{
			get;
			private set;
		}

		public double Y
		{
			get;
			private set;
		}

		public double Weight
		{
			get;
			private set;
		}
	}
}