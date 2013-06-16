
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

@class WeatherView;

@interface WeatherViewController : UIViewController<CLLocationManagerDelegate>
{
    CLLocationManager *locationManager;
    WeatherView *weatherView;
}

@end
