//
//  PSOViewController.m
//  PSOLib
//
//  Created by Ivan Rublev on 11/04/2015.
//  Copyright (c) 2015 Ivan Rublev. All rights reserved. http://ivanrublev.me
//
//  Distributed under the MIT license.
//

#import "PSOViewController.h"
@import PSOLib;
@import CoreGraphics;

NSUInteger const particles = 4;
NSString *const doubleOutputPattern = @"%.2f";

@interface PSOViewController () {
    BOOL wasLayoutedForTheFirstTime;
}
@property (strong, nonatomic) IBOutlet UIView *sceneView;
@property (nonatomic) NSMutableArray* layers;
@property (nonatomic, copy) PSOFitnessBlock func;
@property (nonatomic, assign) double x0;
@property (nonatomic, assign) double x1;
@property (nonatomic, assign) int dimensions;
@property (nonatomic) NSOperationQueue* queue;
@property (nonatomic) Class optimizerClass;

@property (strong, nonatomic) IBOutlet UILabel *x0label;
@property (strong, nonatomic) IBOutlet UILabel *x1label;
@property (strong, nonatomic) IBOutlet UIButton *findButton;
@property (strong, nonatomic) IBOutlet UILabel *iterationLabel;
@property (strong, nonatomic) IBOutlet UILabel *particleXes;
@property (strong, nonatomic) IBOutlet UILabel *globalMinX;
@property (strong, nonatomic) IBOutlet UISwitch *circleTopologySwitch;
@property (nonatomic) BOOL layersHidden;

@property (nonatomic) BOOL search;
@end

@implementation PSOViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.queue = [NSOperationQueue new];
    self.queue.maxConcurrentOperationCount = 1;

    self.func = ^double(double* x, int dimensions) { // Rastrigin
        double sum = 10.*dimensions;
        for (int d=0; d<dimensions; d++) {
            sum += (x[d]*x[d] - 10.*cos(2.*M_PI*x[d]));
        }
        return sum;
    };
    self.x0 = -5.12;
    self.x1 = 5.12;
    self.dimensions = 1;

    self.optimizerClass = [PSOStandardOptimizer2011 class];
    self.circleTopologySwitch.on = NO;
    
    self.iterationLabel.text = @"";
    self.particleXes.text = @"";
    self.globalMinX.text = @"";
}

- (void)viewDidLayoutSubviews {
    if (wasLayoutedForTheFirstTime == NO) {
        wasLayoutedForTheFirstTime = YES;
        [self makeLayers];
        self.search = NO;
    }
}

- (void)makeLayers {
    double stepX = 0.01;
    double xVec[] = {self.x0};
    double y0 = self.func(xVec, self.dimensions);
    double y1 = 50.;
    
    CGFloat scaleX = self.sceneView.bounds.size.width/(self.x1-self.x0);
    CGFloat scaleY = self.sceneView.bounds.size.height/(y1-0.);
    CATransform3D transform = CATransform3DMakeAffineTransform(CGAffineTransformTranslate(CGAffineTransformMakeScale(scaleX, -scaleY), -self.x0, -y1));
    
    CGMutablePathRef funcPath = CGPathCreateMutable();
    CGPathMoveToPoint(funcPath, nil, self.x0, y0);
    for (double x=self.x0+stepX; x<=self.x1; x+=stepX) {
        xVec[0] = x;
        double y = self.func(xVec, self.dimensions);
        CGPathAddLineToPoint(funcPath, nil, x, y);
    }
    for (double x=self.x1; x>self.x0; x-=stepX) {
        xVec[0] = x;
        double y = self.func(xVec, self.dimensions);
        CGPathAddLineToPoint(funcPath, nil, x, y);
    }
    CGPathCloseSubpath(funcPath);
    
    CAShapeLayer* funcLayer = [CAShapeLayer layer];
    funcLayer.path = funcPath;
    funcLayer.lineWidth = 1./MAX(scaleX, scaleY);
    funcLayer.strokeColor = [[UIColor darkGrayColor] CGColor];
    funcLayer.transform = transform;
    
    [self.sceneView.layer addSublayer:funcLayer];
    [self.layers addObject:funcLayer];
    
    
    double scaleYtoX = scaleY/scaleX;
    double roundSize = 5.;
    self.layers = [NSMutableArray array];
    for (NSUInteger p=0; p<particles; p++) {
        CAShapeLayer* circleLayer = [CAShapeLayer layer];
        CGMutablePathRef circlePath = CGPathCreateMutable();
        CGPathAddEllipseInRect(circlePath, nil, CGRectMake(0., 0., scaleYtoX, 1.));
        circleLayer.bounds = CGRectMake(0, 0, scaleYtoX, 1);
        circleLayer.path = circlePath;
        circleLayer.fillColor = [[UIColor redColor] CGColor];
        circleLayer.transform = CATransform3DMakeAffineTransform(CGAffineTransformMakeScale(roundSize, roundSize));
        [self.layers addObject:circleLayer];
    }
    
    [self.layers enumerateObjectsUsingBlock:^(CAShapeLayer* layer, NSUInteger idx, BOOL *stop) {
        layer.position = CGPointMake(0, 0);
        layer.hidden = YES;
        [funcLayer addSublayer:layer];
    }];
}

- (PSOStandardOptimizer2011*)optimizer {
    PSOStandardOptimizer2011* optimizer = [self.optimizerClass
                           optimizerForSearchSpace:[PSOSearchSpace searchSpaceWithDimensionsMin:self.x0 max:self.x1 count:self.dimensions]
                           optimum:0.
                           fitness:self.func
                           before:nil
                           iteration:^(PSOStandardOptimizer2011 *optimizer) {
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   NSMutableArray* positionsStr = [NSMutableArray array];
                                   [optimizer.particlesPositions enumerateObjectsUsingBlock:^(NSArray* xNumberArray, NSUInteger idx, BOOL *stop) {
                                       CAShapeLayer* circleLayer = self.layers[idx];
                                       double x = [xNumberArray[0] doubleValue];
                                       double y = [optimizer.particlesFitness[idx] doubleValue];
                                       circleLayer.position = CGPointMake(x, y);
                                       [positionsStr addObject:[NSString stringWithFormat:doubleOutputPattern, x]];
                                   }];
                                   self.particleXes.text = [positionsStr componentsJoinedByString:@", "];
                                   self.globalMinX.text = [NSString stringWithFormat:doubleOutputPattern, [optimizer.bestPosition[0] doubleValue]];
                                   self.iterationLabel.text = [NSString stringWithFormat:@"%lu of %lu", (unsigned long)optimizer.iteration+1, (unsigned long)optimizer.maxIterations];
                               });
                               usleep(USEC_PER_SEC*0.2);
                           }
                           finished:^(PSOStandardOptimizer2011 *optimizer) {
                               double minX = [optimizer.bestPosition[0] doubleValue];
                               double minXFitness = optimizer.bestFitness;
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   [self setSearchNOWithMinX:minX fitness:minXFitness];
                               });
                           }];
    optimizer.fitnessError = 1e-3;
    optimizer.populationSize = particles;
    optimizer.maxIterations = 50;
    return optimizer;
}

- (void)setSearch:(BOOL)search {
    _search = search;
    self.particleXes.hidden = ! search;
    self.layersHidden = ! search;
    [self updateFindButtonTitle];
    if (search) {
        PSOStandardOptimizer2011* optimizer = self.optimizer;
        NSLog(@"optimizer class: %@", NSStringFromClass(optimizer.class));
        [self.queue addOperation:optimizer.operation];
    } else {
        [self.queue cancelAllOperations];
    }
}

- (void)setSearchNOWithMinX:(double)x fitness:(double)fitness {
    _search = NO;
    self.particleXes.hidden = YES;
    [self setLayersHidden:NO atPosition:CGPointMake(x, fitness)];
    [self updateFindButtonTitle];
}

- (void)setLayersHidden:(BOOL)hidden {
    _layersHidden = hidden;
    [self.layers enumerateObjectsUsingBlock:^(CAShapeLayer* layer, NSUInteger idx, BOOL *stop) {
        layer.hidden = hidden;
    }];
}

- (void)setLayersHidden:(BOOL)hidden atPosition:(CGPoint)position {
    _layersHidden = hidden;
    [self.layers enumerateObjectsUsingBlock:^(CAShapeLayer* layer, NSUInteger idx, BOOL *stop) {
        layer.position = position;
        layer.hidden = hidden;
    }];
}

- (void)updateFindButtonTitle {
    [self.findButton setTitle:self.search ? @"Stop" : @"Search" forState:UIControlStateNormal];
}

- (void)setX0:(double)x0 {
    _x0 = x0;
    self.x0label.text = [NSString stringWithFormat:doubleOutputPattern, x0];
}

- (void)setX1:(double)x1 {
    _x1 = x1;
    self.x1label.text = [NSString stringWithFormat:doubleOutputPattern, x1];
}

- (IBAction)findButtonPressed:(id)sender {
    self.search = ! self.search;
}

- (IBAction)circleTopologySwitchChanged:(id)sender {
    if (self.circleTopologySwitch.on) {
        self.optimizerClass = [PSOStandardOptimizer2011CircleTopology class];
    } else {
        self.optimizerClass = [PSOStandardOptimizer2011 class];
    }
}
@end
