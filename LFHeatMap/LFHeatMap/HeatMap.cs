namespace LFHeatMap
{
	public static class HeatMap
	{
		public static byte[] HeatMapForRectangle(Rect rect, double boost, PointWithWeight[] points, bool weightsAdjustmentEnabled, bool groupingEnabled)
		{
			// Adjustment variables for weights adjustment
			float weightSensitivity = 1; // Percents from maximum weight
			float weightBoostTo = 50; // Percents to boost least sensible weight to

			// Adjustment variables for grouping
			int groupingThreshold = 10;  // Increasing this will improve performance with less accuracy. Negative will disable grouping
			int peaksRemovalThreshold = 20; // Should be greater than groupingThreshold
			float peaksRemovalFactor = 0.4F; // Should be from 0 (no peaks removal) to 1 (peaks are completely lowered to zero)
			if (points == null || rect.Width <= 0 || rect.Width <= 0)
			{
				//NSLog(@"LFHeatMap: heatMapWithRect: incorrect arguments");
				return null;
			}

			int width = (int)rect.Width;
			int height = (int)rect.Height;
			int i, j;

			// According to heatmap API, boost is heat radius multiplier
			int radius = (int)(50 * boost);

			// RGBA array is initialized with 0s
			byte[] rgba = new byte[(width * height * 4)];
			int[] density = new int[(width * height)];

			// Step 1
			// Copy points into plain array (plain array iteration is faster than accessing NSArray objects)
			int points_num = points.Length;
			int[] point_x = new int[points_num];
			int[] point_y = new int[points_num];
			double[] point_weight_percent = new double[points_num];
			double[] point_weight = new double[points_num];
			double max_weight = 0;
			point_weight = new double[points_num];


			i = 0;
			j = 0;
			foreach (var pointValue in points)
			{

				point_x[i] = (int)(pointValue.X - rect.X);
				point_y[i] = (int)(pointValue.Y - rect.Y);

				// Filter out of range points
				if (point_x[i] < 0 - radius ||
					point_y[i] < 0 - radius ||
					point_x[i] >= rect.Width + radius ||
					point_y[i] >= rect.Height + radius)
				{
					points_num--;
					j++;
					// Do not increment i, to replace this point in next iteration (or drop if it is last one)
					// but increment j to leave consistency when accessing weights
					continue;
				}

				// Fill weights if available
				point_weight[i] = pointValue.Weight;
				if (max_weight < point_weight[i])
					max_weight = point_weight[i];

				i++;
				j++;
			}

			// Step 1.5
			// Normalize weights to be 0 .. 100 (like percents)
			// Weights array should be integer for not slowing down calculation by
			// int-float conversion and float multiplication
			double absWeightSensitivity = (max_weight / 100.0) * weightSensitivity;
			double absWeightBoostTo = (max_weight / 100.0) * weightBoostTo;
			for (i = 0; i < points_num; i++)
			{
				if (weightsAdjustmentEnabled)
				{
					if (point_weight[i] <= absWeightSensitivity)
						point_weight[i] *= absWeightBoostTo / absWeightSensitivity;
					else
						point_weight[i] = absWeightBoostTo + (point_weight[i] - absWeightSensitivity) * ((max_weight - absWeightBoostTo) / (max_weight - absWeightSensitivity));
				}
				point_weight_percent[i] = 100.0 * (point_weight[i] / max_weight);
			}
			point_weight = null;

			// Step 1.75 (optional)
			// Grouping and filtering bunches of points in same location
			int currentDistance;
			int currentDensity;

			if (groupingEnabled)
				GroupPoints(groupingThreshold, peaksRemovalThreshold, peaksRemovalFactor, points_num, point_x, point_y, point_weight_percent);

			// Step 2
			// Fill density info. Density is calculated around each point
			int from_x, from_y, to_x, to_y;
			for (i = 0; i < points_num; i++)
			{
				if (point_weight_percent[i] > 0)
				{
					from_x = point_x[i] - radius;
					from_y = point_y[i] - radius;
					to_x = point_x[i] + radius;
					to_y = point_y[i] + radius;

					if (from_x < 0)
						from_x = 0;
					if (from_y < 0)
						from_y = 0;
					if (to_x > width)
						to_x = width;
					if (to_y > height)
						to_y = height;


					for (int y = from_y; y < to_y; y++)
					{
						for (int x = from_x; x < to_x; x++)
						{
							currentDistance = (x - point_x[i]) * (x - point_x[i]) + (y - point_y[i]) * (y - point_y[i]);

							currentDensity = radius - Helpers.ISqrt(currentDistance);
							if (currentDensity < 0)
								currentDensity = 0;

							density[y * width + x] += (int)(currentDensity * point_weight_percent[i]);
						}
					}
				}
			}

			point_x = null;
			point_y = null;
			point_weight_percent = null;

			// Step 2.5
			// Find max density (doing this in step 2 will have less performance)
			int maxDensity = density[0];
			for (i = 1; i < width * height; i++)
			{
				if (maxDensity < density[i])
					maxDensity = density[i];
			}

			// Step 3
			// Render density info into raw RGBA pixels
			i = 0;
			float floatDensity;
			uint indexOrigin;
			for (int y = 0; y < height; y++)
			{
				for (int x = 0; x < width; x++, i++)
				{
					if (density[i] > 0)
					{
						indexOrigin = (uint)(4 * i);
						// Normalize density to 0..1
						floatDensity = (float)density[i] / (float)maxDensity;

						// Red and alpha component
						rgba[indexOrigin] = (byte)(floatDensity * 255);
						rgba[indexOrigin + 3] = rgba[indexOrigin];

						// Green component
						if (floatDensity >= 0.75)
							rgba[indexOrigin + 1] = rgba[indexOrigin];
						else if (floatDensity >= 0.5)
							rgba[indexOrigin + 1] = (byte)((floatDensity - 0.5) * 255 * 3);


						// Blue component
						if (floatDensity >= 0.8)
							rgba[indexOrigin + 2] = (byte)((floatDensity - 0.8) * 255 * 5);
					}
				}
			}

			density = null; ;
			return rgba;
		}

		static void GroupPoints(int groupingThreshold, int peaksRemovalThreshold, float peaksRemovalFactor, int points_num, int[] point_x, int[] point_y, double[] point_weight_percent)
		{
			int currentDistance;
			for (int i = 0; i < points_num; i++)
			{
				if (point_weight_percent[i] > 0)
				{
					for (int j = i + 1; j < points_num; j++)
					{
						if (point_weight_percent[j] > 0)
						{
							if (i == -1)
								continue;
							currentDistance = Helpers.ISqrt((point_x[i] - point_x[j]) * (point_x[i] - point_x[j]) + (point_y[i] - point_y[j]) * (point_y[i] - point_y[j]));

							if (currentDistance > peaksRemovalThreshold)
								currentDistance = peaksRemovalThreshold;

							float K1 = 1 - peaksRemovalFactor;
							float K2 = peaksRemovalFactor;

							// Lowering peaks
							point_weight_percent[i] =
							K1 * point_weight_percent[i] +
							K2 * point_weight_percent[i] * (float)((float)(currentDistance) / (float)peaksRemovalThreshold);

							// Performing grouping if two points are closer than groupingThreshold
							if (currentDistance <= groupingThreshold)
							{
								// Merge i and j points. Store result in [i], remove [j]
								point_x[i] = (point_x[i] + point_x[j]) / 2;
								point_y[i] = (point_y[i] + point_y[j]) / 2;
								point_weight_percent[i] = point_weight_percent[i] + point_weight_percent[j];

								// point_weight_percent[j] is set negative to be avoided
								point_weight_percent[j] = -10;

								// Repeat again for new point
								i--;
							}
						}
					}
				}
			}
		}
	}
}