//
//  PSOLibPSOStandardOptimizer2011Tests.m
//  PSOLibTests
//
//  Created by Ivan Rublev on 11/6/15.
//  Copyright (c) 2015 Ivan Rublev. All rights reserved. http://ivanrublev.me
//
//  Distributed under the MIT license.
//

#import <Specta/Specta.h>
#import <Expecta/Expecta.h>
@import PSOLib;
@import Accelerate;


SpecBegin(PSOStandardOptimizer2011)

__block PSOStandardOptimizer2011* optimizer;
__block NSUInteger iterations;
__block double fitnessBest;

describe(@"Test functions", ^{
    __block double optimum;
    __block double fitnessError;
    __block NSUInteger expectedIterations;

    void (^prepareOptimizer)(PSOSearchSpace* bounds, double optimum, PSOFitnessBlock fitness) = ^(PSOSearchSpace* bounds, double optimum, PSOFitnessBlock fitness) {
        optimizer =
        [PSOStandardOptimizer2011
         optimizerForSearchSpace:bounds
         optimum:optimum
         fitness:fitness
         before:nil
         iteration:nil
         finished:^(PSOStandardOptimizer2011* optimizer) {
             iterations = optimizer.iteration;
             fitnessBest = optimizer.bestFitness;
         }];
        optimizer.fitnessError = fitnessError;
        PSOAleaSrand(1294404794);
    };

    beforeEach(^{
        optimum = 0.;
        fitnessError = 1e-4;
        expectedIterations = 2e3;
    });
    it(@"Sphere", ^{
        
        fitnessError = 0.01;
        
        prepareOptimizer([PSOSearchSpace searchSpaceWithDimensionsMin:-100 max:100 count:30], optimum, ^double(double* x, int dimensions) { // sum(x.^2);
            double squares[dimensions];
            vDSP_vsqD(x, 1, squares, 1, dimensions);
            double sum = 0;
            vDSP_sveD(squares, 1, &sum, dimensions);
            return sum;
        });
        [optimizer.operation start];
        
        expectedIterations = 250;
        expect(fitnessBest).to.beCloseToWithin(optimum, fitnessError);
        expect(iterations).to.beLessThan(expectedIterations);
    });
    it(@"Rastrigin", ^{
        
        fitnessError = 50;
        
        prepareOptimizer([PSOSearchSpace searchSpaceWithDimensionsMin:-5.12 max:5.12 count:30], optimum, ^double(double* x, int dimensions) { // 10*D + sum(x.^2 - 10*cos(2.*pi.*x));
            double sum = 10.*dimensions;
            for (int d=0; d<dimensions; d++) {
                sum += (x[d]*x[d] - 10.*cos(2.*M_PI*x[d]));
            }
            return sum;
        });
        [optimizer.operation start];

        expect(fitnessBest).to.beCloseToWithin(optimum, fitnessError);
        expect(iterations).to.beLessThan(expectedIterations);
    });
    it(@"Step", ^{
        prepareOptimizer([PSOSearchSpace searchSpaceWithDimensionsMin:-100 max:100 count:10], optimum, ^double(double* x, int dimensions) { // sum(floor(x + 0.5).^2);
            double sum = 0.;
            for (int d=0; d<dimensions; d++) {
                int xd = (int)(x[d]+0.5);
                sum += xd*xd;
            }
            return sum;
        });
        [optimizer.operation start];
        
        expectedIterations = 70;
        expect(fitnessBest).to.beCloseToWithin(optimum, fitnessError);
        expect(iterations).to.beLessThan(expectedIterations);
    });
    it(@"Rosenbrock", ^{
        
        fitnessError = 100;
        
        prepareOptimizer([PSOSearchSpace searchSpaceWithDimensionsMin:-30 max:30 count:30], optimum, ^double(double* x, int dimensions) {
            double sum = 0.;
            for (int d=0; d<dimensions-1; d++) {
                sum += 100.*(pow(x[d+1]-x[d]*x[d], 2.) + pow(1-x[d], 2.));
            }
            return sum;
        });
        [optimizer.operation start];
        expect(fitnessBest).to.beCloseToWithin(optimum, fitnessError);
        expect(iterations).to.beLessThan(expectedIterations);
    });
});

describe(@"Simplest one dimention test function for two particles search", ^{
    it(@"Sphere", ^{
        __block NSArray* xBest = nil;
        __block BOOL beforeWasCalled = NO;
        __block BOOL iterationWasCalled = NO;
        NSUInteger tag = 123;
        optimizer =
        [PSOStandardOptimizer2011
         optimizerForSearchSpace:[PSOSearchSpace searchSpaceWithBoundsMin:@[@-100] max:@[@100]]
         optimum:0.
         fitness:^double(double* x, int dimensions) { // sum(x.^2);
             double squares[dimensions];
             vDSP_vsqD(x, 1, squares, 1, dimensions);
             double sum = 0;
             vDSP_sveD(squares, 1, &sum, dimensions);
             return sum;
         } before:^(PSOStandardOptimizer2011* optimizer) {
             beforeWasCalled = YES;
             XCTAssertThrows(optimizer.optimum = 10.);
             XCTAssertTrue(optimizer.tag == tag);
         } iteration:^(PSOStandardOptimizer2011* optimizer) {
             iterationWasCalled = YES;
             XCTAssertThrows(optimizer.optimum = 10.);
             XCTAssertTrue(optimizer.tag == tag);
         } finished:^(PSOStandardOptimizer2011* optimizer) {
             iterations = optimizer.iteration;
             fitnessBest = optimizer.bestFitness;
             xBest = optimizer.bestPosition;
             XCTAssertThrows(optimizer.optimum = 10.);
             XCTAssertTrue(optimizer.tag == tag);
         }];
        optimizer.populationSize = 2;
        optimizer.tag = tag;
        [optimizer.operation start];
        expect(fitnessBest).to.beCloseToWithin(0, DBL_EPSILON);
        expect(iterations).to.beLessThan(300);
        expect(xBest.firstObject).to.beCloseToWithin(0, 1e-7);
        expect(beforeWasCalled).to.equal(YES);
        expect(iterationWasCalled).to.equal(YES);
        double* x = malloc(sizeof(double));
        x[0] = [xBest.firstObject doubleValue];
        expect(optimizer.fitnessFunction(x, 1)).to.beCloseToWithin(0, DBL_EPSILON);
        free(x);
    });
    it(@"Sphere (one dimention is zero length)", ^{
        optimizer =
        [PSOStandardOptimizer2011
         optimizerForSearchSpace:[PSOSearchSpace searchSpaceWithBoundsMin:@[@0, @-100] max:@[@0, @100]]
         optimum:0.
         fitness:^double(double* x, int dimensions) { // sum(x.^2);
             double squares[dimensions];
             vDSP_vsqD(x, 1, squares, 1, dimensions);
             double sum = 0;
             vDSP_sveD(squares, 1, &sum, dimensions);
             return sum;
         }
         before:nil
         iteration:nil
         finished:^(PSOStandardOptimizer2011* optimizer) {
             iterations = optimizer.iteration;
             fitnessBest = optimizer.bestFitness;
         }];
        optimizer.populationSize = 2;
        [optimizer.operation start];
        expect(fitnessBest).to.beCloseToWithin(0, DBL_EPSILON);
        expect(iterations).to.beLessThan(300);
    });
});

SpecEnd