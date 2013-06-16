
#define MARGIN 3

typedef void (^DictBlock)(NSDictionary *dict);
typedef void (^ImageBlock)(UIImage *image);

#import <UIKit/UIKit.h>

@interface WeatherView : UIView
{
    UILabel *dateLabel;
    UILabel *maxTempLabel,*minTempLabel;
    UIImageView *weatherIcon;
}

-(void) weatherFromLocation:(CGPoint)location complete:(DictBlock)dictBlock;

@end
