//
//  PSOFitnessCalculatingTests.m
//  PSOLibTests
//
//  Created by Ivan Rublev on 11/7/15.
//  Copyright (c) 2015 Ivan Rublev. All rights reserved. http://ivanrublev.me
//
//  Distributed under the MIT license.
//

@import PSOLib;
@import Accelerate;
#import <XCTest/XCTest.h>

@interface PSOFitnessCalculatingTests : XCTestCase <PSOFitnessCalculating>
@property BOOL numberOfPositionsInBunchWasCalled;
@property BOOL delegateCalculationMethodWasCalled;
@end

@implementation PSOFitnessCalculatingTests

- (void)testFitnessDelegate {
    __block double fitnessBest;
    PSOStandardOptimizer2011* opt =
    [PSOStandardOptimizer2011 optimizerForSearchSpace:[PSOSearchSpace searchSpaceWithDimensionsMin:-100 max:100 count:3]
                              optimum:0.
                         fitnessCalculator:self
                                  before:nil
                               iteration:nil
                                finished:^(PSOStandardOptimizer2011* optimizer) {
                                    fitnessBest = optimizer.bestFitness;
                                }];
    opt.fitnessError = 1e-4;
    opt.populationSize = 5;
    [opt.operation start];
    XCTAssertTrue(fabs(fitnessBest)<opt.fitnessError);
    XCTAssertTrue(self.numberOfPositionsInBunchWasCalled);
    XCTAssertTrue(self.delegateCalculationMethodWasCalled);

}

#pragma mark -
#pragma mark PSOBunch delegate
- (NSUInteger)numberOfPositionsInBunch:(PSOStandardOptimizer2011*)optimizer {
    self.numberOfPositionsInBunchWasCalled = YES;
    return 2;
}

- (void)optimizer:(PSOStandardOptimizer2011*)optimizer getFitnessValues:(out double *)fitnessValues forPositionsBunch:(double**)positions size:(NSUInteger)bunchSize dimensions:(int)dimensions {
    self.delegateCalculationMethodWasCalled = YES;
    XCTAssertTrue(bunchSize == 2 || bunchSize == 1);
    for (NSUInteger bunch=0; bunch<bunchSize; bunch++) {
        double squares[dimensions];
        vDSP_vsqD(positions[bunch], 1, squares, 1, dimensions);
        double sum = 0;
        vDSP_sveD(squares, 1, &sum, dimensions);
        fitnessValues[bunch] = sum;
    }
}

@end
