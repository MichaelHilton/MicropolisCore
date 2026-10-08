#include "../src/micropolis.h"
#include "include/micropolis_c.h"

#include <unistd.h>
#include <climits>

class CCallback : public Callback {
public:
    MPCallbacks cbs = {};

    virtual ~CCallback() {}
    virtual void autoGoto(Micropolis *micropolis, emscripten::val callbackVal, int x, int y, std::string message) override {
        if (cbs.autoGoto) cbs.autoGoto(cbs.context, x, y, message.c_str());
    }
    virtual void didGenerateMap(Micropolis *micropolis, emscripten::val callbackVal, int seed) override {
        if (cbs.didGenerateMap) cbs.didGenerateMap(cbs.context, seed);
    }
    virtual void didLoadCity(Micropolis *micropolis, emscripten::val callbackVal, std::string filename) override {
        if (cbs.didLoadCity) cbs.didLoadCity(cbs.context, filename.c_str());
    }
    virtual void didLoadScenario(Micropolis *micropolis, emscripten::val callbackVal, std::string name, std::string fname) override {}
    virtual void didLoseGame(Micropolis *micropolis, emscripten::val callbackVal) override {
        if (cbs.didLoseGame) cbs.didLoseGame(cbs.context);
    }
    virtual void didSaveCity(Micropolis *micropolis, emscripten::val callbackVal, std::string filename) override {}
    virtual void didTool(Micropolis *micropolis, emscripten::val callbackVal, std::string name, int x, int y) override {
        if (cbs.didTool) cbs.didTool(cbs.context, name.c_str(), x, y);
    }
    virtual void didWinGame(Micropolis *micropolis, emscripten::val callbackVal) override {
        if (cbs.didWinGame) cbs.didWinGame(cbs.context);
    }
    virtual void didntLoadCity(Micropolis *micropolis, emscripten::val callbackVal, std::string filename) override {}
    virtual void didntSaveCity(Micropolis *micropolis, emscripten::val callbackVal, std::string filename) override {}
    virtual void makeSound(Micropolis *micropolis, emscripten::val callbackVal, std::string channel, std::string sound, int x, int y) override {
        if (cbs.makeSound) cbs.makeSound(cbs.context, channel.c_str(), sound.c_str(), x, y);
    }
    virtual void newGame(Micropolis *micropolis, emscripten::val callbackVal) override {}
    virtual void saveCityAs(Micropolis *micropolis, emscripten::val callbackVal, std::string filename) override {}
    virtual void sendMessage(Micropolis *micropolis, emscripten::val callbackVal, int messageIndex, int x, int y, bool picture, bool important) override {
        if (cbs.sendMessage) cbs.sendMessage(cbs.context, messageIndex, x, y, picture ? 1 : 0, important ? 1 : 0);
    }
    virtual void showBudgetAndWait(Micropolis *micropolis, emscripten::val callbackVal) override {
        if (cbs.showBudgetAndWait) cbs.showBudgetAndWait(cbs.context);
    }
    virtual void showZoneStatus(Micropolis *micropolis, emscripten::val callbackVal, int tileCategoryIndex, int populationDensityIndex, int landValueIndex, int crimeRateIndex, int pollutionIndex, int growthRateIndex, int x, int y) override {
        if (cbs.showZoneStatus) cbs.showZoneStatus(cbs.context, tileCategoryIndex, populationDensityIndex, landValueIndex, crimeRateIndex, pollutionIndex, growthRateIndex, x, y);
    }
    virtual void simulateRobots(Micropolis *micropolis, emscripten::val callbackVal) override {}
    virtual void simulateChurch(Micropolis *micropolis, emscripten::val callbackVal, int posX, int posY, int churchNumber) override {}
    virtual void startEarthquake(Micropolis *micropolis, emscripten::val callbackVal, int strength) override {
        if (cbs.startEarthquake) cbs.startEarthquake(cbs.context, strength);
    }
    virtual void startGame(Micropolis *micropolis, emscripten::val callbackVal) override {}
    virtual void startScenario(Micropolis *micropolis, emscripten::val callbackVal, int scenario) override {}
    virtual void updateBudget(Micropolis *micropolis, emscripten::val callbackVal) override {
        if (cbs.updateBudget) cbs.updateBudget(cbs.context);
    }
    virtual void updateCityName(Micropolis *micropolis, emscripten::val callbackVal, std::string cityName) override {
        if (cbs.updateCityName) cbs.updateCityName(cbs.context, cityName.c_str());
    }
    virtual void updateDate(Micropolis *micropolis, emscripten::val callbackVal, int cityYear, int cityMonth) override {
        if (cbs.updateDate) cbs.updateDate(cbs.context, cityYear, cityMonth);
    }
    virtual void updateDemand(Micropolis *micropolis, emscripten::val callbackVal, float r, float c, float i) override {
        if (cbs.updateDemand) cbs.updateDemand(cbs.context, r, c, i);
    }
    virtual void updateEvaluation(Micropolis *micropolis, emscripten::val callbackVal) override {
        if (cbs.updateEvaluation) cbs.updateEvaluation(cbs.context);
    }
    virtual void updateFunds(Micropolis *micropolis, emscripten::val callbackVal, int totalFunds) override {
        if (cbs.updateFunds) cbs.updateFunds(cbs.context, totalFunds);
    }
    virtual void updateGameLevel(Micropolis *micropolis, emscripten::val callbackVal, int gameLevel) override {}
    virtual void updateHistory(Micropolis *micropolis, emscripten::val callbackVal) override {
        if (cbs.updateHistory) cbs.updateHistory(cbs.context);
    }
    virtual void updateMap(Micropolis *micropolis, emscripten::val callbackVal) override {}
    virtual void updateOptions(Micropolis *micropolis, emscripten::val callbackVal) override {}
    virtual void updatePasses(Micropolis *micropolis, emscripten::val callbackVal, int passes) override {}
    virtual void updatePaused(Micropolis *micropolis, emscripten::val callbackVal, bool simPaused) override {
        if (cbs.updatePaused) cbs.updatePaused(cbs.context, simPaused ? 1 : 0);
    }
    virtual void updateSpeed(Micropolis *micropolis, emscripten::val callbackVal, int speed) override {
        if (cbs.updateSpeed) cbs.updateSpeed(cbs.context, speed);
    }
    virtual void updateTaxRate(Micropolis *micropolis, emscripten::val callbackVal, int cityTax) override {
        if (cbs.updateTaxRate) cbs.updateTaxRate(cbs.context, cityTax);
    }
};

struct MPEngine {
    Micropolis sim;
    CCallback *callback;
    bool animateAll = true;
    bool frequentAnimation = true;
    unsigned long tickCount = 0;
};

/** Copies a coarse overlay map out at one value per world tile. */
template <typename MAP>
static void copyOverlay(const MAP &map, short *out) {
    for (int x = 0; x < WORLD_W; x++) {
        for (int y = 0; y < WORLD_H; y++) {
            out[x * WORLD_H + y] = (short)map.worldGet(x, y);
        }
    }
}

extern "C" {

MPEngine *mp_create(void) {
    MPEngine *e = new MPEngine();
    e->callback = new CCallback();
    e->sim.setCallback(e->callback, emscripten::val::null());
    e->sim.init();
    return e;
}

void mp_destroy(MPEngine *e) {
    delete e;
}

int mp_load_city(MPEngine *e, const char *path) {
    return e->sim.loadCity(path) ? 1 : 0;
}

void mp_tick(MPEngine *e) {
    e->sim.simTick();
    e->tickCount++;
    if (e->animateAll && (e->frequentAnimation || e->tickCount % 2 == 0)) {
        e->sim.animateTiles();
    }
}

void mp_set_animation(MPEngine *e, int animateAll, int frequent) {
    e->animateAll = animateAll != 0;
    e->frequentAnimation = frequent != 0;
}

int mp_animate_all(MPEngine *e) {
    return e->animateAll ? 1 : 0;
}

int mp_frequent_animation(MPEngine *e) {
    return e->frequentAnimation ? 1 : 0;
}

long mp_total_funds(MPEngine *e) {
    return e->sim.totalFunds;
}

int mp_city_year(MPEngine *e) {
    return (int)e->sim.cityYear;
}

int mp_city_month(MPEngine *e) {
    return (int)e->sim.cityMonth;
}

const unsigned short *mp_map(MPEngine *e) {
    return (const unsigned short *)e->sim.getMapAddress();
}

long mp_city_pop(MPEngine *e) {
    return e->sim.cityPop;
}

int mp_city_score(MPEngine *e) {
    return e->sim.cityScore;
}

int mp_city_class(MPEngine *e) {
    return e->sim.cityClass;
}

int mp_city_tax(MPEngine *e) {
    return e->sim.cityTax;
}

void mp_set_city_tax(MPEngine *e, int tax) {
    e->sim.setCityTax(tax);
}

void mp_get_demands(MPEngine *e, float *r, float *c, float *i) {
    e->sim.getDemands(r, c, i);
}

float mp_road_percent(MPEngine *e) {
    return e->sim.roadPercent;
}

float mp_police_percent(MPEngine *e) {
    return e->sim.policePercent;
}

float mp_fire_percent(MPEngine *e) {
    return e->sim.firePercent;
}

void mp_set_road_percent(MPEngine *e, float p) {
    e->sim.roadPercent = p;
    e->sim.updateFundEffects();
}

void mp_set_police_percent(MPEngine *e, float p) {
    e->sim.policePercent = p;
    e->sim.updateFundEffects();
}

void mp_set_fire_percent(MPEngine *e, float p) {
    e->sim.firePercent = p;
    e->sim.updateFundEffects();
}

void mp_set_funds(MPEngine *e, long funds) {
    e->sim.setFunds((int)funds);
}

void mp_set_passes(MPEngine *e, int passes) {
    e->sim.setPasses(passes);
}

void mp_set_speed(MPEngine *e, int speed) {
    e->sim.setSpeed(speed);
}

void mp_pause(MPEngine *e) {
    e->sim.pause();
}

void mp_resume(MPEngine *e) {
    e->sim.resume();
}

int mp_is_paused(MPEngine *e) {
    return e->sim.simPaused ? 1 : 0;
}

void mp_set_auto_budget(MPEngine *e, int enable) {
    e->sim.setAutoBudget(enable != 0);
}

void mp_set_auto_bulldoze(MPEngine *e, int enable) {
    e->sim.setAutoBulldoze(enable != 0);
}

void mp_set_enable_disasters(MPEngine *e, int enable) {
    e->sim.setEnableDisasters(enable != 0);
}

int mp_passes(MPEngine *e) {
    return e->sim.simPasses;
}

int mp_speed(MPEngine *e) {
    return e->sim.simSpeedMeta;
}

int mp_auto_budget(MPEngine *e) {
    return e->sim.autoBudget ? 1 : 0;
}

int mp_auto_bulldoze(MPEngine *e) {
    return e->sim.autoBulldoze ? 1 : 0;
}

int mp_enable_disasters(MPEngine *e) {
    return e->sim.enableDisasters ? 1 : 0;
}

void mp_generate_map(MPEngine *e, int seed) {
    e->sim.generateMap(seed);
}

int mp_do_tool(MPEngine *e, int tool, int x, int y) {
    return e->sim.doTool((EditingTool)tool, x, y);
}

int mp_save_city(MPEngine *e, const char *path) {
    return e->sim.saveFile(path) ? 1 : 0;
}

void mp_make_disaster(MPEngine *e, int which) {
    switch (which) {
        case 0: e->sim.makeFire(); break;
        case 1: e->sim.makeFlood(); break;
        case 2: e->sim.makeEarthquake(); break;
        case 3: e->sim.makeMonster(); break;
        case 4: e->sim.makeTornado(); break;
        case 5: e->sim.makeMeltdown(); break;
        case 6: {
            // DOS "Air Crash": blow up a plane in flight, as a mid-air
            // collision does in doAirplaneSprite.
            SimSprite *plane = e->sim.getSprite(SPRITE_AIRPLANE);
            if (plane) e->sim.explodeSprite(plane);
            break;
        }
    }
}

int mp_get_sprites(MPEngine *e, MPSprite *out, int maxCount) {
    int count = 0;
    for (SimSprite *sprite = e->sim.spriteList; sprite && count < maxCount; sprite = sprite->next) {
        if (sprite->frame != 0) {
            out[count].type = sprite->type;
            out[count].frame = sprite->frame;
            out[count].x = sprite->x;
            out[count].y = sprite->y;
            out[count].xHot = sprite->xHot;
            out[count].yHot = sprite->yHot;
            count++;
        }
    }
    return count;
}

void mp_get_history(MPEngine *e, int which, short *out) {
    short *src;
    switch (which) {
        case MP_HISTORY_RESIDENTIAL: src = e->sim.resHist; break;
        case MP_HISTORY_COMMERCIAL: src = e->sim.comHist; break;
        case MP_HISTORY_INDUSTRIAL: src = e->sim.indHist; break;
        case MP_HISTORY_MONEY: src = e->sim.moneyHist; break;
        case MP_HISTORY_CRIME: src = e->sim.crimeHist; break;
        case MP_HISTORY_POLLUTION: src = e->sim.pollutionHist; break;
        default: return;
    }
    for (int i = 0; i < 480; i++) {
        out[i] = src[i];
    }
}

void mp_get_overlay(MPEngine *e, int which, short *out) {
    Micropolis &sim = e->sim;
    switch (which) {
        case MP_OVERLAY_POPULATION: copyOverlay(sim.populationDensityMap, out); break;
        case MP_OVERLAY_GROWTH: copyOverlay(sim.rateOfGrowthMap, out); break;
        case MP_OVERLAY_TRAFFIC: copyOverlay(sim.trafficDensityMap, out); break;
        case MP_OVERLAY_POLLUTION: copyOverlay(sim.pollutionDensityMap, out); break;
        case MP_OVERLAY_CRIME: copyOverlay(sim.crimeRateMap, out); break;
        case MP_OVERLAY_LAND_VALUE: copyOverlay(sim.landValueMap, out); break;
        case MP_OVERLAY_POLICE: copyOverlay(sim.policeStationEffectMap, out); break;
        case MP_OVERLAY_FIRE: copyOverlay(sim.fireStationEffectMap, out); break;
        case MP_OVERLAY_POWER: copyOverlay(sim.powerGridMap, out); break;
    }
}

void mp_get_evaluation(MPEngine *e, MPEvaluation *out) {
    Micropolis &sim = e->sim;
    out->yes = sim.cityYes;
    for (int i = 0; i < 4; i++) {
        int problem = sim.problemOrder[i];
        bool valid = problem >= 0 && problem < CVP_NUMPROBLEMS;
        out->problems[i] = valid ? problem : -1;
        out->problemVotes[i] = valid ? sim.problemVotes[problem] : 0;
    }
    out->population = sim.cityPop;
    out->populationDelta = sim.cityPopDelta;
    out->assessedValue = sim.cityAssessedValue;
    out->cityClass = sim.cityClass;
    out->gameLevel = sim.gameLevel;
    out->score = sim.cityScore;
    out->scoreDelta = sim.cityScoreDelta;
}

void mp_get_budget(MPEngine *e, MPBudget *out) {
    out->taxFund = e->sim.taxFund;
    out->roadFund = e->sim.roadFund;
    out->policeFund = e->sim.policeFund;
    out->fireFund = e->sim.fireFund;
}

int mp_game_level(MPEngine *e) {
    return (int)e->sim.gameLevel;
}

void mp_set_game_level(MPEngine *e, int level) {
    if (level < LEVEL_FIRST || level > LEVEL_LAST) level = LEVEL_EASY;
    e->sim.setGameLevelFunds((GameLevel)level);
}

void mp_set_city_name(MPEngine *e, const char *name) {
    e->sim.setCityName(name);
}

int mp_load_scenario(MPEngine *e, int scenario, const char *resourceDir) {
    if (scenario < SC_DULLSVILLE || scenario > SC_RIO) return 0;
    // loadScenario opens "cities/..." relative to the working directory.
    char previous[PATH_MAX];
    if (!getcwd(previous, sizeof previous)) return 0;
    if (chdir(resourceDir) != 0) return 0;
    if (access("cities", R_OK) != 0) {
        chdir(previous);
        return 0;
    }
    e->sim.loadScenario((Scenario)scenario);
    int ok = chdir(previous) == 0;
    return ok ? 1 : 0;
}

void mp_set_tile(MPEngine *e, int x, int y, unsigned short cell) {
    if (x < 0 || x >= WORLD_W || y < 0 || y >= WORLD_H) return;
    e->sim.map[x][y] = cell;
}

void mp_smooth_terrain(MPEngine *e) {
    Micropolis &sim = e->sim;
    // smoothWater marks shorelines as REDGE; smoothRiver picks edge tiles.
    sim.smoothWater();
    sim.smoothRiver();
    for (int x = 0; x < WORLD_W; x++) {
        for (int y = 0; y < WORLD_H; y++) {
            if (sim.isTree(sim.map[x][y])) {
                sim.smoothTreesAt(x, y, true);
            }
        }
    }
}

void mp_set_callbacks(MPEngine *e, const MPCallbacks *callbacks) {
    e->callback->cbs = *callbacks;
}

}
