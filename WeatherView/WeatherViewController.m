
#import "WeatherView.h"
#import "WeatherViewController.h"

@implementation WeatherViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor colorWithRed:0.8 green:1.0 blue:1.0 alpha:1.0]];
    
    //********************** WeatherView の設置 ***********************//
    
    weatherView = [[WeatherView alloc] initWithFrame:CGRectMake(40, 10, 240, 80)];
    [self.view addSubview:weatherView];
    
    //****************************************************************//
    
    locationManager = [[CLLocationManager alloc] init];
    if ([CLLocationManager locationServicesEnabled]) {
		[locationManager setDelegate:self];
		[locationManager startUpdatingLocation];
	}else{
        NSLog(@"location cannot used");
    }
    
    UILabel *description = [[UILabel alloc] initWithFrame:CGRectMake(20, weatherView.frame.origin.y+weatherView.frame.size.height+10, 290, [[UIScreen mainScreen] applicationFrame].size.height-weatherView.frame.origin.y-weatherView.frame.size.height-20)];
    [description setBackgroundColor:[UIColor clearColor]];
    [description setTextAlignment:NSTextAlignmentLeft];
    [description setNumberOfLines:0];
    [description setFont:[UIFont systemFontOfSize:18]];
    [description setTextColor:[UIColor blackColor]];
    [description setText:@" WeatherViewはLivedoorが提供しているお天気API Weather Hacksを利用して現在地のお天気情報を取得し視覚的に表示してくれるクラスです。\nGithub: https://github.com/tatyusa/WeatherView\nWeather Hacksの利用規約に従いWeatherViewを商用利用することはできません"];
    [self.view addSubview:description];
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    static BOOL isUpdated = NO;
    CLLocationCoordinate2D coordinate = newLocation.coordinate;
    if(coordinate.latitude!=0&&coordinate.longitude!=0)
    {
        isUpdated = YES;
        CGPoint location = CGPointMake(coordinate.latitude, coordinate.longitude);
        
        [weatherView weatherFromLocation:location complete:^(NSDictionary *dict) {
            NSLog(@"%@",dict);
        }];
        
        [locationManager stopUpdatingLocation];
    }
}

@end
