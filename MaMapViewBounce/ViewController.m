//
//  ViewController.m
//  MaMapViewBounce
//
//  Created by 王帅 on 12/21/18.
//  Copyright © 2018 王帅. All rights reserved.
//

#import "ViewController.h"
#import <AMapFoundationKit/AMapFoundationKit.h>
#import "WSMAMapView.h"
@interface ViewController ()<MAMapViewDelegate>
@property (strong, nonatomic) WSMAMapView *mapView;
@property (strong, nonatomic) MAUserLocation * userLocation;
@property (strong, nonatomic)MAGroundOverlay *groundOverlay;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _mapView = [[WSMAMapView alloc]initWithFrame:self.view.bounds];
    _mapView.showsLabels = NO;
    _mapView.showsCompass = NO;
    _mapView.showsScale  = NO;
    _mapView.showsBuildings = NO;
    _mapView.showsIndoorMap  = NO; _mapView.customizeUserLocationAccuracyCircleRepresentation = YES; // 去除精度圈。
    [_mapView setUserTrackingMode:MAUserTrackingModeNone];
    [self.view addSubview:_mapView];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    _mapView.delegate = self;
    _mapView.showsUserLocation = YES;//这句就是开启定位
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    _mapView.delegate = nil;
    _mapView.showsUserLocation = NO;//这句就是关闭定位
}
#pragma mark  - mapView delegate
- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation{//处理位置坐标更新
    if (_userLocation == nil) {//开始重新查找
        _userLocation = userLocation;
       [self addBackMapPhoto:[UIImage imageWithData:[self resetSizeOfImageData:[UIImage imageNamed:@"青川县.jpg"] maxSize:4000]]];
        [_mapView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[UIImageView class]]) {
                UIImageView * logoM = obj;
                logoM.layer.contents = (__bridge id)[self imageWithColor:[UIColor clearColor]].CGImage;
            }
        }];//去除高德地图logo
    }
}

-(void)addBackMapPhoto:(UIImage *)image{
    MACoordinateBounds coordinateBounds =  MACoordinateBoundsMake(CLLocationCoordinate2DMake(33.573508 ,105.725429 ),CLLocationCoordinate2DMake (31.459197,104.49496));
    _groundOverlay = [MAGroundOverlay groundOverlayWithBounds:coordinateBounds icon:image];
    [_mapView addOverlay:_groundOverlay];//添加盖印图片
    
    MACoordinateRegion limitRegion;
    limitRegion.center = CLLocationCoordinate2DMake((33.573508 + 31.459197)/2.0, (105.725429 + 104.49496)/2.0);
    MACoordinateSpan span;
    span.latitudeDelta= coordinateBounds.northEast.latitude -coordinateBounds.southWest.latitude;
    span.longitudeDelta =  coordinateBounds.northEast.longitude -coordinateBounds.southWest.longitude;
    limitRegion.span =  span;
    _mapView.limitRegion = limitRegion;
    
    _mapView.rotateEnabled = NO;
    _mapView.rotateCameraEnabled = NO;
    _mapView.groundOverlay = _groundOverlay;
}

- (void)mapView:(MAMapView *)mapView didAnnotationViewCalloutTapped:(MAAnnotationView *)view{
    if ([view.annotation isKindOfClass:[MAUserLocation class]]) {
        return;
    }
}

- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id<MAOverlay>)overlay{
    if ([overlay isKindOfClass:[MAGroundOverlay class]]){
        MAGroundOverlayRenderer *groundOverlayRenderer = [[MAGroundOverlayRenderer alloc] initWithGroundOverlay:overlay];
        return groundOverlayRenderer;
    }
    return nil;
}

// 颜色转换为背景图片 注意 四个取值， 会影响最终颜色
-(UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

-(NSData *)resetSizeOfImageData:(UIImage *)source_image maxSize:(NSInteger)maxSize{
    //先调整分辨率
    CGSize newSize = CGSizeMake(source_image.size.width, source_image.size.height);
    CGFloat tempHeight = newSize.height / maxSize;
    CGFloat tempWidth = newSize.width / maxSize;
    newSize = CGSizeMake(source_image.size.width / tempWidth, source_image.size.height / tempHeight);
    
    UIGraphicsBeginImageContext(newSize);
    [source_image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //调整大小
    NSData *imageData = UIImageJPEGRepresentation(newImage,1);
    NSUInteger sizeOrigin = [imageData length];
    NSUInteger sizeOriginKB = sizeOrigin / 1024;
    if (sizeOriginKB > maxSize) {
        NSData *finallImageData = UIImageJPEGRepresentation(newImage,0.8);
        return finallImageData;
    }
    return imageData;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
