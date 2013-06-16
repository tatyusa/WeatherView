
#import "WeatherView.h"

@implementation WeatherView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor whiteColor]];
        
        weatherIcon = [[UIImageView alloc] initWithFrame:CGRectMake(MARGIN, MARGIN, frame.size.height-MARGIN, frame.size.height-MARGIN)];
        [weatherIcon setContentMode:UIViewContentModeScaleAspectFit];
        
        dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(weatherIcon.frame.size.width+MARGIN, 0, frame.size.width-weatherIcon.frame.size.width-MARGIN, frame.size.height*3/5)];
        [dateLabel setBackgroundColor:[UIColor clearColor]];
        [dateLabel setTextAlignment:NSTextAlignmentCenter];
        [dateLabel setAdjustsFontSizeToFitWidth:YES];
        [dateLabel setFont:[UIFont systemFontOfSize:dateLabel.frame.size.height/2]];
        [dateLabel setTextColor:[UIColor blackColor]];
        
        maxTempLabel = [[UILabel alloc] initWithFrame:CGRectMake(dateLabel.frame.origin.x, dateLabel.frame.size.height, (frame.size.width-weatherIcon.frame.size.width-MARGIN)/2, frame.size.height-dateLabel.frame.size.height-10)];
        [maxTempLabel setBackgroundColor:[UIColor clearColor]];
        [maxTempLabel setTextAlignment:NSTextAlignmentCenter];
        [maxTempLabel setAdjustsFontSizeToFitWidth:YES];
        [maxTempLabel setFont:[UIFont systemFontOfSize:maxTempLabel.frame.size.height*5/6]];
        [maxTempLabel setTextColor:[UIColor redColor]];
        
        minTempLabel = [[UILabel alloc] initWithFrame:CGRectMake(maxTempLabel.frame.origin.x+maxTempLabel.frame.size.width, maxTempLabel.frame.origin.y, maxTempLabel.frame.size.width, maxTempLabel.frame.size.height)];
        [minTempLabel setBackgroundColor:[UIColor clearColor]];
        [minTempLabel setTextAlignment:NSTextAlignmentCenter];
        [minTempLabel setAdjustsFontSizeToFitWidth:YES];
        [minTempLabel setFont:[UIFont systemFontOfSize:minTempLabel.frame.size.height*5/6]];
        [minTempLabel setTextColor:[UIColor blueColor]];
        
        UILabel *rightLabel = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width-80-MARGIN, minTempLabel.frame.origin.y+minTempLabel.frame.size.height, 80, 10)];
        [rightLabel setBackgroundColor:[UIColor clearColor]];
        [rightLabel setTextAlignment:NSTextAlignmentCenter];
        [rightLabel setFont:[UIFont systemFontOfSize:8]];
        [rightLabel setTextColor:[UIColor blueColor]];
        [rightLabel setText:@"Weather Hacks"];
        [rightLabel setUserInteractionEnabled:YES];
        [rightLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showRight)]];
        
        [self addSubview:weatherIcon];
        [self addSubview:dateLabel];
        [self addSubview:maxTempLabel];
        [self addSubview:minTempLabel];
        [self addSubview:rightLabel];
    }
    return self;
}

-(void) weatherFromLocation:(CGPoint)location complete:(DictBlock)dictBlock
{
    // 現在地に最も近い地域を探索
    NSDictionary *candidate;
    double distance = MAXFLOAT;
    for(NSDictionary *dict in [self mapData])
    {
        if([self distance:location from:[dict[@"location"] CGPointValue]]<distance)
        {
            candidate = dict;
            distance = [self distance:location from:[dict[@"location"] CGPointValue]];
        }
    }
    
    // Weather Hacks から情報を取得
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSString *url = [NSString stringWithFormat:@"http://weather.livedoor.com/forecast/webservice/json/v1?city=%@",candidate[@"id"]];
        NSDictionary *dict = [self getWeatherInfo:url];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if([dict count]>0)
            {
                // 天気アイコンを取得・設定
                [self getImageWithURL:dict[@"forecasts"][1][@"image"][@"url"] complete:^(UIImage *image) {
                    [weatherIcon setImage:image];
                }];
                
                // 各情報を設定
                [self setLocation:dict[@"location"][@"prefecture"] date:dict[@"forecasts"][1][@"dateLabel"]];
                [self setMaxTemperature:[dict[@"forecasts"][1][@"temperature"][@"max"][@"celsius"] intValue]];
                [self setMinTemperature:[dict[@"forecasts"][1][@"temperature"][@"min"][@"celsius"] intValue]];
                
                // コールバック関数
                dictBlock(dict);
            }
        });
    });
}

/// 場所と日付を設定
-(void)setLocation:(NSString *)location date:(NSString *)date
{
    [dateLabel setText:[NSString stringWithFormat:@"%@ %@",location,date]];
}

/// 最高気温を設定
- (void)setMaxTemperature:(int)temperature
{
    [maxTempLabel setText:[NSString stringWithFormat:@"%d℃",temperature]];
}

/// 最低気温を設定
- (void)setMinTemperature:(int)temperature
{
    [minTempLabel setText:[NSString stringWithFormat:@"%d℃",temperature]];
}

/// URLから画像を取得
- (void)getImageWithURL:(NSString *)url complete:(ImageBlock)imageBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSURL* nsurl = [NSURL URLWithString:url];
        NSData* data = [NSData dataWithContentsOfURL:nsurl];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            imageBlock([[UIImage alloc] initWithData:data]);
        });
    });
}

/// 二点間の距離を計算
- (double)distance:(CGPoint)p1 from:(CGPoint)p2
{
    return sqrt(pow((p1.x-p2.x),2)+pow((p1.y-p2.y),2));
}

/// Weather Hacks から天気情報を取得
- (NSDictionary *)getWeatherInfo:(NSString *)url
{
    NSDictionary *dict = [[NSDictionary alloc] init];
    
    NSURL *nsurl = [NSURL URLWithString:url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:nsurl cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    [request setHTTPMethod:@"GET"];
    
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    
    if(data.length>0){
        dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        return dict;
    }else{
        NSLog(@"Server Response is Null");
    }
    return dict;
}

/// 一次細分区と緯度経度の組み合わせ
- (NSArray *)mapData
{
    return @[@{@"name":@"稚内",@"id":@"011000",@"location":[NSValue valueWithCGPoint:CGPointMake(45.40,141.65)]},
                       @{@"name":@"網走",@"id":@"013010",@"location":[NSValue valueWithCGPoint:CGPointMake(44.01,144.27)]},
                       @{@"name":@"室蘭",@"id":@"015010",@"location":[NSValue valueWithCGPoint:CGPointMake(42.32,140.98)]},
                       @{@"name":@"札幌",@"id":@"016010",@"location":[NSValue valueWithCGPoint:CGPointMake(43.05,141.36)]},
                       @{@"name":@"函館",@"id":@"017010",@"location":[NSValue valueWithCGPoint:CGPointMake(41.77,140.72)]},
                       @{@"name":@"青森",@"id":@"020010",@"location":[NSValue valueWithCGPoint:CGPointMake(40.70,140.87)]},
                       @{@"name":@"盛岡",@"id":@"030010",@"location":[NSValue valueWithCGPoint:CGPointMake(39.70,141.18)]},
                       @{@"name":@"仙台",@"id":@"040010",@"location":[NSValue valueWithCGPoint:CGPointMake(38.27,140.88)]},
                       @{@"name":@"秋田",@"id":@"050010",@"location":[NSValue valueWithCGPoint:CGPointMake(39.85,140.42)]},
                       @{@"name":@"山形",@"id":@"060010",@"location":[NSValue valueWithCGPoint:CGPointMake(38.25,140.35)]},
                       @{@"name":@"福島",@"id":@"070010",@"location":[NSValue valueWithCGPoint:CGPointMake(37.33,139.97)]},
                       @{@"name":@"水戸",@"id":@"080010",@"location":[NSValue valueWithCGPoint:CGPointMake(36.37,140.48)]},
                       @{@"name":@"宇都宮",@"id":@"090010",@"location":[NSValue valueWithCGPoint:CGPointMake(36.57,139.88)]},
                       @{@"name":@"前橋",@"id":@"100010",@"location":[NSValue valueWithCGPoint:CGPointMake(36.38,139.07)]},
                       @{@"name":@"熊谷",@"id":@"110020",@"location":[NSValue valueWithCGPoint:CGPointMake(36.15,139.40)]},
                       @{@"name":@"千葉",@"id":@"120010",@"location":[NSValue valueWithCGPoint:CGPointMake(35.63,140.28)]},
                       @{@"name":@"東京",@"id":@"130010",@"location":[NSValue valueWithCGPoint:CGPointMake(35.67,139.57)]},
                       @{@"name":@"横浜",@"id":@"140010",@"location":[NSValue valueWithCGPoint:CGPointMake(35.47,139.63)]},
                       @{@"name":@"新潟",@"id":@"150010",@"location":[NSValue valueWithCGPoint:CGPointMake(37.27,138.73)]},
                       @{@"name":@"富山",@"id":@"160010",@"location":[NSValue valueWithCGPoint:CGPointMake(36.60,137.15)]},
                       @{@"name":@"金沢",@"id":@"170010",@"location":[NSValue valueWithCGPoint:CGPointMake(36.57,136.65)]},
                       @{@"name":@"福井",@"id":@"180010",@"location":[NSValue valueWithCGPoint:CGPointMake(35.93,136.40)]},
                       @{@"name":@"甲府",@"id":@"190010",@"location":[NSValue valueWithCGPoint:CGPointMake(35.65,138.57)]},
                       @{@"name":@"長野",@"id":@"200010",@"location":[NSValue valueWithCGPoint:CGPointMake(36.20,138.07)]},
                       @{@"name":@"岐阜",@"id":@"210010",@"location":[NSValue valueWithCGPoint:CGPointMake(35.98,137.08)]},
                       @{@"name":@"静岡",@"id":@"220010",@"location":[NSValue valueWithCGPoint:CGPointMake(35.10,138.32)]},
                       @{@"name":@"名古屋",@"id":@"230010",@"location":[NSValue valueWithCGPoint:CGPointMake(35.18,136.88)]},
                       @{@"name":@"津",@"id":@"240010",@"location":[NSValue valueWithCGPoint:CGPointMake(34.72,136.50)]},
                       @{@"name":@"大津",@"id":@"250010",@"location":[NSValue valueWithCGPoint:CGPointMake(35.02,135.87)]},
                       @{@"name":@"京都",@"id":@"260010",@"location":[NSValue valueWithCGPoint:CGPointMake(35.22,135.53)]},
                       @{@"name":@"大阪",@"id":@"270000",@"location":[NSValue valueWithCGPoint:CGPointMake(34.55,135.48)]},
                       @{@"name":@"神戸",@"id":@"280010",@"location":[NSValue valueWithCGPoint:CGPointMake(34.72,135.17)]},
                       @{@"name":@"奈良",@"id":@"290010",@"location":[NSValue valueWithCGPoint:CGPointMake(34.17,135.83)]},
                       @{@"name":@"和歌山",@"id":@"300010",@"location":[NSValue valueWithCGPoint:CGPointMake(34.02,135.37)]},
                       @{@"name":@"鳥取",@"id":@"310010",@"location":[NSValue valueWithCGPoint:CGPointMake(35.06,132.60)]},
                       @{@"name":@"松江",@"id":@"320010",@"location":[NSValue valueWithCGPoint:CGPointMake(35.46,133.05)]},
                       @{@"name":@"岡山",@"id":@"330010",@"location":[NSValue valueWithCGPoint:CGPointMake(34.66,133.92)]},
                       @{@"name":@"広島",@"id":@"340010",@"location":[NSValue valueWithCGPoint:CGPointMake(34.37,132.44)]},
                       @{@"name":@"下関",@"id":@"350010",@"location":[NSValue valueWithCGPoint:CGPointMake(33.95,130.93)]},
                       @{@"name":@"徳島",@"id":@"360010",@"location":[NSValue valueWithCGPoint:CGPointMake(34.066,134.56)]},
                       @{@"name":@"高松",@"id":@"370000",@"location":[NSValue valueWithCGPoint:CGPointMake(34.338539,134.046204)]},
                       @{@"name":@"松山",@"id":@"380010",@"location":[NSValue valueWithCGPoint:CGPointMake(33.835091,132.774902)]},
                       @{@"name":@"高知",@"id":@"390010",@"location":[NSValue valueWithCGPoint:CGPointMake(33.552010,133.538300)]},
                       @{@"name":@"福岡",@"id":@"400010",@"location":[NSValue valueWithCGPoint:CGPointMake(33.579788,130.402405)]},
                       @{@"name":@"佐賀",@"id":@"410010",@"location":[NSValue valueWithCGPoint:CGPointMake(33.246601,130.303101)]},
                       @{@"name":@"長崎",@"id":@"420010",@"location":[NSValue valueWithCGPoint:CGPointMake(32.765419,129.866302)]},
                       @{@"name":@"熊本",@"id":@"430010",@"location":[NSValue valueWithCGPoint:CGPointMake(32.788521,130.714905)]},
                       @{@"name":@"大分",@"id":@"440010",@"location":[NSValue valueWithCGPoint:CGPointMake(33.231110,131.606201)]},
                       @{@"name":@"宮崎",@"id":@"450010",@"location":[NSValue valueWithCGPoint:CGPointMake(31.907379,131.423203)]},
                       @{@"name":@"鹿児島",@"id":@"460010",@"location":[NSValue valueWithCGPoint:CGPointMake(31.570539,130.552505)]},
                       @{@"name":@"那覇",@"id":@"471010",@"location":[NSValue valueWithCGPoint:CGPointMake(26.204830,127.692398)]}];
}

- (void)showRight
{
    NSURL *url = [NSURL URLWithString:@"http://weather.livedoor.com/weather_hacks/"];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
}

@end
