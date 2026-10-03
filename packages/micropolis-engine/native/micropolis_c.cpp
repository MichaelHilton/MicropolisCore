#include "../src/micropolis.h"
#include "include/micropolis_c.h"

class CCallback : public Callback {
public:
    virtual ~CCallback() {}
    virtual void autoGoto(Micropolis *micropolis, emscripten::val callbackVal, int x, int y, std::string message) override {}
    virtual void didGenerateMap(Micropolis *micropolis, emscripten::val callbackVal, int seed) override {}
    virtual void didLoadCity(Micropolis *micropolis, emscripten::val callbackVal, std::string filename) override {}
    virtual void didLoadScenario(Micropolis *micropolis, emscripten::val callbackVal, std::string name, std::string fname) override {}
    virtual void didLoseGame(Micropolis *micropolis, emscripten::val callbackVal) override {}
    virtual void didSaveCity(Micropolis *micropolis, emscripten::val callbackVal, std::string filename) override {}
    virtual void didTool(Micropolis *micropolis, emscripten::val callbackVal, std::string name, int x, int y) override {}
    virtual void didWinGame(Micropolis *micropolis, emscripten::val callbackVal) override {}
    virtual void didntLoadCity(Micropolis *micropolis, emscripten::val callbackVal, std::string filename) override {}
    virtual void didntSaveCity(Micropolis *micropolis, emscripten::val callbackVal, std::string filename) override {}
    virtual void makeSound(Micropolis *micropolis, emscripten::val callbackVal, std::string channel, std::string sound, int x, int y) override {}
    virtual void newGame(Micropolis *micropolis, emscripten::val callbackVal) override {}
    virtual void saveCityAs(Micropolis *micropolis, emscripten::val callbackVal, std::string filename) override {}
    virtual void sendMessage(Micropolis *micropolis, emscripten::val callbackVal, int messageIndex, int x, int y, bool picture, bool important) override {}
    virtual void showBudgetAndWait(Micropolis *micropolis, emscripten::val callbackVal) override {}
    virtual void showZoneStatus(Micropolis *micropolis, emscripten::val callbackVal, int tileCategoryIndex, int populationDensityIndex, int landValueIndex, int crimeRateIndex, int pollutionIndex, int growthRateIndex, int x, int y) override {}
    virtual void simulateRobots(Micropolis *micropolis, emscripten::val callbackVal) override {}
    virtual void simulateChurch(Micropolis *micropolis, emscripten::val callbackVal, int posX, int posY, int churchNumber) override {}
    virtual void startEarthquake(Micropolis *micropolis, emscripten::val callbackVal, int strength) override {}
    virtual void startGame(Micropolis *micropolis, emscripten::val callbackVal) override {}
    virtual void startScenario(Micropolis *micropolis, emscripten::val callbackVal, int scenario) override {}
    virtual void updateBudget(Micropolis *micropolis, emscripten::val callbackVal) override {}
    virtual void updateCityName(Micropolis *micropolis, emscripten::val callbackVal, std::string cityName) override {}
    virtual void updateDate(Micropolis *micropolis, emscripten::val callbackVal, int cityYear, int cityMonth) override {}
    virtual void updateDemand(Micropolis *micropolis, emscripten::val callbackVal, float r, float c, float i) override {}
    virtual void updateEvaluation(Micropolis *micropolis, emscripten::val callbackVal) override {}
    virtual void updateFunds(Micropolis *micropolis, emscripten::val callbackVal, int totalFunds) override {}
    virtual void updateGameLevel(Micropolis *micropolis, emscripten::val callbackVal, int gameLevel) override {}
    virtual void updateHistory(Micropolis *micropolis, emscripten::val callbackVal) override {}
    virtual void updateMap(Micropolis *micropolis, emscripten::val callbackVal) override {}
    virtual void updateOptions(Micropolis *micropolis, emscripten::val callbackVal) override {}
    virtual void updatePasses(Micropolis *micropolis, emscripten::val callbackVal, int passes) override {}
    virtual void updatePaused(Micropolis *micropolis, emscripten::val callbackVal, bool simPaused) override {}
    virtual void updateSpeed(Micropolis *micropolis, emscripten::val callbackVal, int speed) override {}
    virtual void updateTaxRate(Micropolis *micropolis, emscripten::val callbackVal, int cityTax) override {}
};

struct MPEngine {
    Micropolis sim;
    CCallback *callback;
};

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
    e->sim.animateTiles();
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

}
