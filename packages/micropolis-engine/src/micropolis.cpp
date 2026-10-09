/* micropolis.cpp
 *
 * Micropolis, Unix Version.  This game was released for the Unix platform
 * in or about 1990 and has been modified for inclusion in the One Laptop
 * Per Child program.  Copyright (C) 1989 - 2007 Electronic Arts Inc.  If
 * you need assistance with this program, you may contact:
 *   http://wiki.laptop.org/go/Micropolis  or email  micropolis@laptop.org.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.  You should have received a
 * copy of the GNU General Public License along with this program.  If
 * not, see <http://www.gnu.org/licenses/>.
 *
 *             ADDITIONAL TERMS per GNU GPL Section 7
 *
 * No trademark or publicity rights are granted.  This license does NOT
 * give you any right, title or interest in the trademark SimCity or any
 * other Electronic Arts trademark.  You may not distribute any
 * modification of this program using the trademark SimCity or claim any
 * affliation or association with Electronic Arts Inc. or its employees.
 *
 * Any propagation or conveyance of this program must include this
 * copyright notice and these terms.
 *
 * If you convey this program (or any modifications of it) and assume
 * contractual liability for the program to recipients of it, you agree
 * to indemnify Electronic Arts for any liability that those contractual
 * assumptions impose on Electronic Arts.
 *
 * You may not misrepresent the origins of this program; modified
 * versions of the program must be marked as such and not identified as
 * the original program.
 *
 * This disclaimer supplements the one included in the General Public
 * License.  TO THE FULLEST EXTENT PERMISSIBLE UNDER APPLICABLE LAW, THIS
 * PROGRAM IS PROVIDED TO YOU "AS IS," WITH ALL FAULTS, WITHOUT WARRANTY
 * OF ANY KIND, AND YOUR USE IS AT YOUR SOLE RISK.  THE ENTIRE RISK OF
 * SATISFACTORY QUALITY AND PERFORMANCE RESIDES WITH YOU.  ELECTRONIC ARTS
 * DISCLAIMS ANY AND ALL EXPRESS, IMPLIED OR STATUTORY WARRANTIES,
 * INCLUDING IMPLIED WARRANTIES OF MERCHANTABILITY, SATISFACTORY QUALITY,
 * FITNESS FOR A PARTICULAR PURPOSE, NONINFRINGEMENT OF THIRD PARTY
 * RIGHTS, AND WARRANTIES (IF ANY) ARISING FROM A COURSE OF DEALING,
 * USAGE, OR TRADE PRACTICE.  ELECTRONIC ARTS DOES NOT WARRANT AGAINST
 * INTERFERENCE WITH YOUR ENJOYMENT OF THE PROGRAM; THAT THE PROGRAM WILL
 * MEET YOUR REQUIREMENTS; THAT OPERATION OF THE PROGRAM WILL BE
 * UNINTERRUPTED OR ERROR-FREE, OR THAT THE PROGRAM WILL BE COMPATIBLE
 * WITH THIRD PARTY SOFTWARE OR THAT ANY ERRORS IN THE PROGRAM WILL BE
 * CORRECTED.  NO ORAL OR WRITTEN ADVICE PROVIDED BY ELECTRONIC ARTS OR
 * ANY AUTHORIZED REPRESENTATIVE SHALL CREATE A WARRANTY.  SOME
 * JURISDICTIONS DO NOT ALLOW THE EXCLUSION OF OR LIMITATIONS ON IMPLIED
 * WARRANTIES OR THE LIMITATIONS ON THE APPLICABLE STATUTORY RIGHTS OF A
 * CONSUMER, SO SOME OR ALL OF THE ABOVE EXCLUSIONS AND LIMITATIONS MAY
 * NOT APPLY TO YOU.
 */

/** 
 * @file micropolis.cpp
 * @brief Primary implementation file for the Micropolis game engine.
 *
 * This file contains the core implementation of the Micropolis game
 * engine. It includes the main class constructor, destructor,
 * initialization and destruction functions, and other essential
 * methods that underpin the game's functionality. The file covers
 * various aspects of the game such as simulation control, disaster
 * handling, sound effects, and map manipulation.
 */


////////////////////////////////////////////////////////////////////////


#include "micropolis.h"


////////////////////////////////////////////////////////////////////////


/**
 * Simulator constructor.
 */
Micropolis::Micropolis() :
        populationDensityMap(0),
        trafficDensityMap(0),
        pollutionDensityMap(0),
        landValueMap(0),
        crimeRateMap(0),
        terrainDensityMap(0),
        tempMap1(0),
        tempMap2(0),
        tempMap3(0),
        powerGridMap(0),
        rateOfGrowthMap(0),
        fireStationMap(0),
        fireStationEffectMap(0),
        policeStationMap(0),
        policeStationEffectMap(0),
        comRateMap(0)
{
    initMapArrays();
}


/** Simulator destructor. */
Micropolis::~Micropolis()
{
    destroy();
    setCallback(NULL, emscripten::val::null());
}


void Micropolis::setCallback(Callback *callback0, emscripten::val callbackVal0)
{
    if (callback != NULL) {
        delete callback;
    }
    callback = callback0;
    callbackVal = callbackVal0;
}


/** Initialize simulator variables to a sane default. */
void Micropolis::init()
{
    printf("init");
    
    ////////////////////////////////////////////////////////////////////////
    // allocate.cpp

    // short roadTotal;
    roadTotal = 0;

    // short railTotal;
    railTotal = 0;

    // short firePop;
    firePop = 0;

    // short resPop;
    resPop = 0;

    // short comPop;
    comPop = 0;

    // short indPop;
    indPop = 0;

    // short totalPop;
    totalPop = 0;

    // short totalPopLast;
    totalPopLast = 0;

    // short resZonePop;
    resZonePop = 0;

    // short comZonePop;
    comZonePop = 0;

    // short indZonePop;
    indZonePop = 0;

    // short totalZonePop;
    totalZonePop = 0;

    // short hospitalPop;
    hospitalPop = 0;

    // short churchPop;
    churchPop = 0;

    // short faith;
    faith = 0;

    // short stadiumPop;
    stadiumPop = 0;

    // short policeStationPop;
    policeStationPop = 0;

    // short fireStationPop;
    fireStationPop = 0;

    // short coalPowerPop;
    coalPowerPop = 0;

    // short nuclearPowerPop;
    nuclearPowerPop = 0;

    // short seaportPop;
    seaportPop = 0;

    // short airportPop;
    airportPop = 0;

    // short needHospital;
    needHospital = 0;

    // short needChurch;
    needChurch = 0;

    // short crimeAverage;
    crimeAverage = 0;

    // short pollutionAverage;
    pollutionAverage = 0;

    // short landValueAverage;
    landValueAverage = 0;

    // Quad cityTime;
    cityTime = 0;

    // Quad cityMonth;
    cityMonth = 0;

    // Quad cityYear;
    cityYear = 0;

    // short startingYear;
    startingYear = 0;

    // short resHist10Max;
    resHist10Max = 0;

    // short resHist120Max;
    resHist120Max = 0;

    // short comHist10Max;
    comHist10Max = 0;

    // short comHist120Max;
    comHist120Max = 0;

    // short indHist10Max;
    indHist10Max = 0;

    // short indHist120Max;
    indHist120Max = 0;

    censusChanged = false;

    // Quad roadSpend;
    roadSpend = 0;

    // Quad policeSpend;
    policeSpend = 0;

    // Quad fireSpend;
    fireSpend = 0;

    // Quad roadFund;
    roadFund = 0;

    // Quad policeFund;
    policeFund = 0;

    // Quad fireFund;
    fireFund = 0;

    roadEffect   = 0;
    policeEffect = 0;
    fireEffect   = 0;

    // Quad taxFund;
    taxFund = 0;

    // short cityTax;
    cityTax = 0;

    // bool taxFlag;
    taxFlag = false;

    populationDensityMap.clear();
    trafficDensityMap.clear();
    pollutionDensityMap.clear();
    landValueMap.clear();
    crimeRateMap.clear();
    powerGridMap.clear();
    terrainDensityMap.clear();
    rateOfGrowthMap.clear();
    fireStationMap.clear();
    fireStationEffectMap.clear();
    policeStationMap.clear();
    policeStationEffectMap.clear();
    comRateMap.clear();


    ////////////////////////////////////////////////////////////////////////
    // budget.cpp


    // float roadPercent;
    roadPercent = (float)0.0;

    // float policePercent;
    policePercent = (float)0.0;

    // float firePercent;
    firePercent = (float)0.0;

    // Quad roadValue;
    roadValue = 0;

    // Quad policeValue;
    policeValue = 0;

    // Quad fireValue;
    fireValue = 0;

    // int mustDrawBudget;
    mustDrawBudget = 0;


    ////////////////////////////////////////////////////////////////////////
    // disasters.cpp


    // short floodCount;
    floodCount = 0;


    ////////////////////////////////////////////////////////////////////////
    // evaluate.cpp


    // short cityYes;
    cityYes = 0;

    // short problemVotes[PROBNUM]; /* these are the votes for each  */
    memset(problemVotes, 0, sizeof(short) * PROBNUM);

    // short problemOrder[CVP_PROBLEM_COMPLAINTS]; /* sorted index to above  */
    memset(problemOrder, 0, sizeof(short) * CVP_PROBLEM_COMPLAINTS);

    // Quad cityPop;
    cityPop = 0;

    // Quad cityPopDelta;
    cityPopDelta = 0;

    // Quad cityAssessedValue;
    cityAssessedValue = 0;

    cityClass = CC_VILLAGE;

    // short cityScore;
    cityScore = 0;

    // short cityScoreDelta;
    cityScoreDelta = 0;

    // short trafficAverage;
    trafficAverage = 0;


    ////////////////////////////////////////////////////////////////////////
    // generate.cpp


    // int TreeLevel; /* level for tree creation */
    terrainTreeLevel = -1;

    // int LakeLevel; /* level for lake creation */
    terrainLakeLevel = -1;

    // int CurveLevel; /* level for river curviness */
    terrainCurveLevel = -1;

    // int CreateIsland; /* -1 => 10%, 0 => never, 1 => always */
    terrainCreateIsland = -1;


    ////////////////////////////////////////////////////////////////////////
    // graph.cpp


    graph10Max = 0;
    graph120Max = 0;


    ////////////////////////////////////////////////////////////////////////
    // main.cpp

    // int simLoops;
    simLoops = 0;

    // int simPasses;
    simPasses = 0;

    // int simPass;
    simPass = 0;

    simPaused = false; // Simulation is running

    // int simPausedSpeed;
    simPausedSpeed = 0;

    // std::string cityFileName;
    cityFileName = "";

    // std::string cityName;
    cityName = "";

    // bool tilesAnimated;
    tilesAnimated = false;

    // bool doAnimaton;
    doAnimation = true;


    ////////////////////////////////////////////////////////////////////////
    // message.cpp


    // Quad cityPopLast;
    cityPopLast = 0;

    // short categoryLast;
    categoryLast = 0;

    autoGoto = false;


    ////////////////////////////////////////////////////////////////////////
    // power.cpp


    powerStackPointer = 0;

    // Position powerStackXY[POWER_STACK_SIZE];
    for (int i = 0; i < POWER_STACK_SIZE; i++) {
        powerStackXY[i] = Position();
    }


    ////////////////////////////////////////////////////////////////////////
    // random.cpp


    // UQuad nextRandom;
    nextRandom = 1;

    hasFixedRandomSeed = false;
    fixedRandomSeed = 0;


    ////////////////////////////////////////////////////////////////////////
    // scan.cpp

    // short newMap;
    newMap = 0;

    // short newMapFlags[MAP_TYPE_COUNT];
    memset(newMapFlags, 0, sizeof(short) * MAP_TYPE_COUNT);

    // short cityCenterX;
    cityCenterX = 0;

    // short cityCenterY;
    cityCenterY = 0;

    // short pollutionMaxX;
    pollutionMaxX = 0;

    // short pollutionMaxY;
    pollutionMaxY = 0;

    // short crimeMaxX;
    crimeMaxX = 0;

    // short crimeMaxY;
    crimeMaxY = 0;

    // Quad donDither;
    donDither = 0;


    ////////////////////////////////////////////////////////////////////////
    // simulate.cpp


    valveFlag = false;

    // short crimeRamp;
    crimeRamp = 0;

    // short pollutionRamp;
    pollutionRamp = 0;

    resCap = false; // Do not block residential growth
    comCap = false; // Do not block commercial growth
    indCap = false; // Do not block industrial growth

    // short cashFlow;
    cashFlow = 0;

    // float externalMarket;
    externalMarket = (float)4.0;

    disasterEvent = SC_NONE;

    // short disasterWait;
    disasterWait = 0;

    scoreType = SC_NONE;

    // short scoreWait;
    scoreWait = 0;

    // short poweredZoneCount;
    poweredZoneCount = 0;

    // short unpoweredZoneCount;
    unpoweredZoneCount = 0;

    newPower = false;

    // short cityTaxAverage;
    cityTaxAverage = 0;

    // short simCycle;
    simCycle = 0;

    // short phaseCycle;
    phaseCycle = 0;

    // short speedCycle;
    speedCycle = 0;

    // bool doInitialEval
    doInitialEval = false;

    // int mapSerial;
    mapSerial = 1;

    // short resValve;
    resValve = 0;

    // short comValve;
    comValve = 0;

    // short indValve;
    indValve = 0;


    ////////////////////////////////////////////////////////////////////////
    // sprite.cpp


    //SimSprite *spriteList;
    spriteList = NULL;

    // SimSprite *freeSprites;
    freeSprites = NULL;

    // SimSprite *globalSprites[SPRITE_COUNT];
    memset(globalSprites, 0, sizeof(SimSprite *) * SPRITE_COUNT);

    // int absDist;
    absDist = 0;

    // short spriteCycle;
    spriteCycle = 0;


    ////////////////////////////////////////////////////////////////////////
    // stubs.cpp


    // Quad totalFunds;
    totalFunds = 0;

    autoBulldoze = true;

    autoBudget = true;

    gameLevel = LEVEL_EASY;

    // short initSimLoad;
    initSimLoad = 0;

    scenario = SC_NONE;

    // short simSpeed;
    simSpeed = 0;

    // short simSpeedMeta;
    simSpeedMeta = 0;

    enableSound = false;

    enableDisasters = true;

    evalChanged = false;

    // short blinkFlag;
    blinkFlag = 0;


    ////////////////////////////////////////////////////////////////////////
    // traffic.cpp


    // short curMapStackPointer;
    curMapStackPointer = 0;

    // Position curMapStackXY[MAX_TRAFFIC_DISTANCE+1];
    for (int i = 0; i < MAX_TRAFFIC_DISTANCE + 1; i++) {
        curMapStackXY[i] = Position();
    }

    // short trafMaxX, trafMaxY;
    trafMaxX = 0;
    trafMaxY = 0;


    ////////////////////////////////////////////////////////////////////////
    // update.cpp


    mustUpdateFunds = false;

    mustUpdateOptions = false;

    // Quad cityTimeLast;
    cityTimeLast = 0;

    // Quad cityYearLast;
    cityYearLast = 0;

    // Quad cityMonthLast;
    cityMonthLast = 0;

    // Quad totalFundsLast;
    totalFundsLast = 0;

    // Quad resLast;
    resLast = 0;

    // Quad comLast;
    comLast = 0;

    // Quad indLast;
    indLast = 0;

    simInit();
    doSimInit();

}


void Micropolis::destroy()
{

    destroyMapArrays();

    // TODO: Clean up all other stuff:

}


/** Initialize for a simulation */
void Micropolis::simInit()
{
    setEnableSound(true); // Enable sound
    mustUpdateOptions = true; // Update options displayed at user
    scenario = SC_NONE;
    startingYear = 1900;
    simPasses = 1;
    simPass = 0;
    setAutoGoto(true); // Enable auto-goto
    setCityTax(7);
    cityTime = 50;
    setEnableDisasters(true); // Enable disasters
    setAutoBulldoze(true); // Enable auto bulldoze
    setAutoBudget(true); // Enable auto-budget
    blinkFlag = 1;
    changeEval();
    simPaused = false; // Simulation is running
    simLoops = 0;
    initSimLoad = 2;

    initGraphs();
    initFundingLevel();
    resetMapState();
    resetEditorState();
    clearMap();
    initWillStuff();
    setFunds(5000);
    setGameLevelFunds(LEVEL_EASY);
    setSpeed(3);
    setPasses(1);
}


/**
 * Update ????
 * @todo What is the purpose of this function? (also in relation with
 *       Micropolis::simTick()).
 */
void Micropolis::simUpdate()
{
    blinkFlag = ((tickCount() % 60) < 30) ? 1 : -1;

    if (simSpeed) {
      tilesAnimated = false;
    }

    doUpdateHeads();
    graphDoer();
    updateBudget();
    scoreDoer();
}


void Micropolis::simLoop(bool doSim)
{
   if (doSim) {
       simFrame();
   }

   moveObjects();
   simulateRobots();

   simLoops++;
}


/**
 * Move simulaton forward.
 * @todo What is the purpose of this function? (also in relation with
 *       Micropolis::simUpdate()).
 */
void Micropolis::simTick()
{
    if (simSpeed) {
        for (simPass = 0; simPass < simPasses; simPass++) {
            simLoop(true);
        }
    }
    simUpdate();
}


void Micropolis::simulateRobots()
{
    callback->simulateRobots(this, callbackVal);
}


/**
 * Deduct \a dollars from the player funds.
 * @param dollars Amount of money spent.
 */
void Micropolis::spend(int dollars)
{
    setFunds(totalFunds - dollars);
}


/**
 * Set player funds to \a dollars.
 *
 * Modify the player funds, and warn the front-end about the new amount of
 * money.
 * @param dollars New value for the player funds.
 */
void Micropolis::setFunds(int dollars)
{
    totalFunds = dollars;
    updateFunds();
}


/**
 * Get number of ticks.
 * @todo Figure out what a 'tick' is.
 * @bug Unix version looks wrong, \c time.tv_usec should be divided to get
 *      seconds or \c time.tc_sec should be multiplied.
 */
Quad Micropolis::tickCount()
{
    struct timeval time;
    gettimeofday(&time, 0);
    return (Quad)((time.tv_sec * 60) + (time.tv_usec * 60) / 1000000);
}


/**
 * Claim \a size bytes of memory.
 * @param size Number of bytes to claim.
 * @return Pointer to the claimed memory.
 */
Ptr Micropolis::newPtr(int size)
{
    return (Ptr)malloc(size);
}


/**
 * Release claimed memory.
 * @param data Pointer to previously claimed memory.
 */
void Micropolis::freePtr(void *data)
{
    free(data);
}


/**
 * Tell the front-end a scenario is started.
 * @param scenario The scenario being started.
 * @see Scenario.
 */
void Micropolis::doStartScenario(int scenario)
{
    callback->startScenario(this, callbackVal, scenario);
}


/**
 * Tell the front-end a game is started.
 */
void Micropolis::doStartGame()
{
    callback->startGame(this, callbackVal);
}


/**
 * Tell the front-end to show an earthquake to the user (shaking the map for
 * some time).
 */
void Micropolis::doEarthquake(int strength)
{
    makeSound("city", "ExplosionLow"); // Make the sound all over.

    callback->startEarthquake(this, callbackVal, strength);
}


/** Tell the front-end that the maps are not valid any more */
void Micropolis::invalidateMaps()
{
    mapSerial++;
    callback->updateMap(this, callbackVal);
}


/**
 * Instruct the front-end to make a sound.
 * @param channel Name of the sound channel, which can effect the
 *                sound (location, volume, spatialization, etc).
 *                Use "city" for city sounds effects, and "interface"
 *                for user interface sounds.
 * @param sound   Name of the sound.
 * @param x       Tile X position of sound, 0 to WORLD_W, or -1 for everywhere.
 * @param y       Tile Y position of sound, 0 to WORLD_H, or -1 for everywhere.
 */
void Micropolis::makeSound(const std::string &channel,
                           const std::string &sound,
                           int x, int y)
{
    if (enableSound) {
        callback->makeSound(this, callbackVal, channel, sound, x, y);
    }
}


long Micropolis::getMapAddress()
{
    return (long)mapBase;
}


////////////////////////////////////////////////////////////////////////
