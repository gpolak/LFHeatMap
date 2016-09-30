//
//  RMAttributionViewController.m
//  MapView
//
//  Created by Justin Miller on 6/19/12.
//  Copyright (c) 2012-2013 Mapbox. All rights reserved.
//

#import "RMAttributionViewController.h"

#import "RMMapView.h"
#import "RMTileSource.h"

@interface RMMapView (RMAttributionViewControllerPrivate)

@property (nonatomic, assign) UIViewController *viewControllerPresentingAttribution;

- (void)dismissAttribution:(id)sender;

@end

#pragma mark -

@interface RMAttributionViewController () <UIWebViewDelegate>

@property (nonatomic, weak) RMMapView *mapView;

@end

#pragma mark -

@implementation RMAttributionViewController

- (id)initWithMapView:(RMMapView *)mapView
{
    self = [super initWithNibName:nil bundle:nil];
    
    if (self)
        _mapView = mapView;

    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.title = @"Map Attribution";

    self.view.backgroundColor = (RMPostVersion7 ? [UIColor colorWithWhite:1 alpha:0.9] : [UIColor darkGrayColor]);

    if (RMPreVersion7)
        [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss:)]];

    CGRect frame = (RMPostVersion7 ? self.view.bounds : CGRectMake(0, self.view.bounds.size.height - 70, self.view.bounds.size.width, 60));

    UIWebView *webView = [[UIWebView alloc] initWithFrame:frame];
    webView.delegate = self;
    webView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | (RMPostVersion7 ? UIViewAutoresizingFlexibleHeight : UIViewAutoresizingFlexibleTopMargin);
    webView.scrollView.showsVerticalScrollIndicator = NO;
    webView.backgroundColor = [UIColor clearColor];
    webView.opaque = NO;

    // don't bounce for page curled presentation
    //
    if (RMPreVersion7)
    {
        if ([webView respondsToSelector:@selector(scrollView)])
        {
            webView.scrollView.bounces = NO;
        }
        else
        {
            for (id subview in webView.subviews)
                if ([[subview class] isSubclassOfClass:[UIScrollView class]])
                    ((UIScrollView *)subview).bounces = NO;
        }
    }

    // build up attribution from tile sources
    //
    NSMutableString *attribution = [NSMutableString string];

    for (id <RMTileSource>tileSource in _mapView.tileSources)
    {
        if ([tileSource respondsToSelector:@selector(shortAttribution)])
        {
            if ([attribution length])
                [attribution appendString:@" "];

            if ([tileSource shortAttribution])
                [attribution appendString:[tileSource shortAttribution]];
        }
    }

    // fallback to generic OSM attribution
    //
    if ( ! [attribution length])
        [attribution setString:@"Map data © OpenStreetMap contributors<br/><a href=\"https://mapbox.com/about/maps/\">More</a>"];

    // build up HTML styling
    //
    NSMutableString *contentString = [NSMutableString string];

    [contentString appendString:@"<style type='text/css'>"];

    NSString *linkColor, *textColor, *fontFamily, *fontSize, *margin;

    if (RMPostVersion7)
    {
        CGFloat r,g,b;
        [self.view.tintColor getRed:&r green:&g blue:&b alpha:nil];
        linkColor  = [NSString stringWithFormat:@"rgb(%lu,%lu,%lu)", (unsigned long)(r * 255.0), (unsigned long)(g * 255.0), (unsigned long)(b * 255.0)];
        textColor  = @"black";
        fontFamily = @"Helvetica Neue";
        fontSize   = [NSString stringWithFormat:@"font-size: %lu; ", (unsigned long)[[UIFont preferredFontForTextStyle:UIFontTextStyleBody] pointSize]];
        margin     = @"margin: 20px; ";
    }
    else
    {
        linkColor  = @"white";
        textColor  = @"lightgray";
        fontFamily = @"Helvetica";
        fontSize   = @"";
        margin     = @"";
    }

    [contentString appendString:[NSString stringWithFormat:@"a { color: %@; text-decoration: none; }", linkColor]];
    [contentString appendString:[NSString stringWithFormat:@"body { color: %@; font-family: %@; %@text-align: center; %@}", textColor, fontFamily, fontSize, margin]];
    [contentString appendString:@"</style>"];

    if (RMPostVersion7)
    {
        // add SDK info
        //
        NSString *appName = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleDisplayName"];
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        [dateFormatter setDateFormat:@"yyyy"];
        NSString *currentYear = [dateFormatter stringFromDate:[NSDate date]];
        [attribution insertString:[NSString stringWithFormat:@"%@ uses the Mapbox iOS SDK © %@ Mapbox, Inc.<br/><a href='https://mapbox.com/mapbox-ios-sdk'>More</a><br/><br/>", appName, currentYear] atIndex:0];

        // add tinted logo
        //
        UIImage *logoImage = [RMMapView resourceImageNamed:@"mapbox-logo.png"];
        UIGraphicsBeginImageContextWithOptions(logoImage.size, NO, [[UIScreen mainScreen] scale]);
        [logoImage drawAtPoint:CGPointMake(0, 0)];
        CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeSourceIn);
        CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext(), [self.view.tintColor CGColor]);
        CGContextFillRect(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, logoImage.size.width, logoImage.size.height));
        NSString *tempFile = [[NSTemporaryDirectory() stringByAppendingString:@"/"] stringByAppendingString:[NSString stringWithFormat:@"%f", [NSDate timeIntervalSinceReferenceDate]]];
        [UIImagePNGRepresentation(UIGraphicsGetImageFromCurrentImageContext()) writeToFile:tempFile atomically:YES];
        UIGraphicsEndImageContext();
        [attribution insertString:[NSString stringWithFormat:@"<img src='file://%@' width='100' height='100'/><br/><br/>", tempFile] atIndex:0];
    }

    // add attribution
    //
    [contentString appendString:attribution];

    [webView loadHTMLString:contentString baseURL:nil];
    [self.view addSubview:webView];

    // add activity indicator
    //
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [spinner startAnimating];
    spinner.center = webView.center;
    spinner.tag = 1;
    [self.view insertSubview:spinner atIndex:0];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [_mapView.viewControllerPresentingAttribution shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return [_mapView.viewControllerPresentingAttribution supportedInterfaceOrientations];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    UIWebView *webView = (UIWebView *)self.view.subviews[0];

    if (UIInterfaceOrientationIsLandscape(fromInterfaceOrientation))
        webView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);

    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

#pragma mark -

- (void)dismiss:(id)sender
{
    [self.mapView dismissAttribution:self];
}

#pragma mark -

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked)
    {
        [[UIApplication sharedApplication] openURL:request.URL];
        
        [self performSelector:@selector(dismiss:) withObject:nil afterDelay:0];
    }
    
    return [[request.URL scheme] isEqualToString:@"about"];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [webView stringByEvaluatingJavaScriptFromString:@"document.body.style.webkitTouchCallout='none';"];

    [[self.view viewWithTag:1] removeFromSuperview];
}

@end
