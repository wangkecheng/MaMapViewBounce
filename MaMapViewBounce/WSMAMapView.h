//
//  WSMAMapView.h
//  CommentFrame
//
//  Created by 王帅 on 12/10/18.
//  Copyright © 2018 warron. All rights reserved.
//

#import <MAMapKit/MAMapKit.h> 

@interface WSMAMapView : MAMapView
 
@property (strong, nonatomic)MAGroundOverlay *groundOverlay;
-(BOOL)isMoveMapView;
@end
