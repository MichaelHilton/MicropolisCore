#ifndef MICROPOLIS_C_H
#define MICROPOLIS_C_H
#ifdef __cplusplus
extern "C" {
#endif

typedef struct MPEngine MPEngine;   /* opaque */

enum { MP_WORLD_W = 120, MP_WORLD_H = 100, MP_HISTORY_LENGTH = 480 };

typedef enum {
    MP_TOOL_RESIDENTIAL = 0, MP_TOOL_COMMERCIAL, MP_TOOL_INDUSTRIAL,
    MP_TOOL_FIRESTATION, MP_TOOL_POLICESTATION, MP_TOOL_QUERY, MP_TOOL_WIRE,
    MP_TOOL_BULLDOZER, MP_TOOL_RAILROAD, MP_TOOL_ROAD, MP_TOOL_STADIUM,
    MP_TOOL_PARK, MP_TOOL_SEAPORT, MP_TOOL_COALPOWER, MP_TOOL_NUCLEARPOWER,
    MP_TOOL_AIRPORT, MP_TOOL_NETWORK, MP_TOOL_WATER, MP_TOOL_LAND, MP_TOOL_FOREST
} MPTool;

typedef enum { MP_RESULT_NO_MONEY = -2, MP_RESULT_NEED_BULLDOZE = -1, MP_RESULT_FAILED = 0, MP_RESULT_OK = 1 } MPToolResult;

typedef struct { int type, frame, x, y, xHot, yHot; } MPSprite;

typedef struct MPCallbacks {
    void *context;
    void (*didLoadCity)(void *ctx, const char *filename);
    void (*didGenerateMap)(void *ctx, int seed);
    void (*didTool)(void *ctx, const char *name, int x, int y);
    void (*makeSound)(void *ctx, const char *channel, const char *sound, int x, int y);
    void (*sendMessage)(void *ctx, int messageIndex, int x, int y, int picture, int important);
    void (*autoGoto)(void *ctx, int x, int y, const char *message);
    void (*showBudgetAndWait)(void *ctx);
    void (*showZoneStatus)(void *ctx, int tileCategory, int density, int landValue,
                           int crime, int pollution, int growth, int x, int y);
    void (*updateDate)(void *ctx, int year, int month);
    void (*updateFunds)(void *ctx, int funds);
    void (*updateDemand)(void *ctx, float r, float c, float i);
    void (*updateCityName)(void *ctx, const char *name);
    void (*updateEvaluation)(void *ctx);
    void (*updateHistory)(void *ctx);
    void (*updateBudget)(void *ctx);
    void (*updatePaused)(void *ctx, int paused);
    void (*updateSpeed)(void *ctx, int speed);
    void (*updateTaxRate)(void *ctx, int tax);
    void (*startEarthquake)(void *ctx, int strength);
    void (*didWinGame)(void *ctx);
    void (*didLoseGame)(void *ctx);
} MPCallbacks;

MPEngine *mp_create(void);
void mp_destroy(MPEngine *e);

int  mp_load_city(MPEngine *e, const char *path);   /* 1 = ok, 0 = failed */
void mp_tick(MPEngine *e);                          /* simTick + animateTiles */

long mp_total_funds(MPEngine *e);
int  mp_city_year(MPEngine *e);
int  mp_city_month(MPEngine *e);
long mp_city_pop(MPEngine *e);
int  mp_city_score(MPEngine *e);
int  mp_city_class(MPEngine *e);
int  mp_city_tax(MPEngine *e);
void mp_set_city_tax(MPEngine *e, int tax);

/* Pointer to MP_WORLD_W*MP_WORLD_H cells, column-major: index = x*MP_WORLD_H + y. */
const unsigned short *mp_map(MPEngine *e);

void mp_get_demands(MPEngine *e, float *r, float *c, float *i);
float mp_road_percent(MPEngine *e);
float mp_police_percent(MPEngine *e);
float mp_fire_percent(MPEngine *e);
void mp_set_road_percent(MPEngine *e, float p);
void mp_set_police_percent(MPEngine *e, float p);
void mp_set_fire_percent(MPEngine *e, float p);
void mp_set_funds(MPEngine *e, long funds);
void mp_set_passes(MPEngine *e, int passes);
void mp_set_speed(MPEngine *e, int speed);
void mp_pause(MPEngine *e);
void mp_resume(MPEngine *e);
int  mp_is_paused(MPEngine *e);
void mp_set_auto_budget(MPEngine *e, int enable);
void mp_set_auto_bulldoze(MPEngine *e, int enable);
void mp_set_enable_disasters(MPEngine *e, int enable);
int  mp_passes(MPEngine *e);
int  mp_speed(MPEngine *e);                         /* the speed last set, even while paused */
int  mp_auto_budget(MPEngine *e);
int  mp_auto_bulldoze(MPEngine *e);
int  mp_enable_disasters(MPEngine *e);
void mp_generate_map(MPEngine *e, int seed);
int  mp_do_tool(MPEngine *e, int tool, int x, int y);
int  mp_save_city(MPEngine *e, const char *path);
void mp_make_disaster(MPEngine *e, int which);

int  mp_get_sprites(MPEngine *e, MPSprite *out, int maxCount);

/* History series for the graphs window. Each is MP_HISTORY_LENGTH shorts;
 * index 0 is newest. 0..119 is the 10-year series, 120..239 the 120-year one. */
typedef enum {
    MP_HISTORY_RESIDENTIAL = 0, MP_HISTORY_COMMERCIAL, MP_HISTORY_INDUSTRIAL,
    MP_HISTORY_MONEY, MP_HISTORY_CRIME, MP_HISTORY_POLLUTION
} MPHistory;
void mp_get_history(MPEngine *e, int which, short *out);

/* Disasters for mp_make_disaster. MP_DISASTER_AIR_CRASH does nothing if no plane is flying. */
typedef enum {
    MP_DISASTER_FIRE = 0, MP_DISASTER_FLOOD, MP_DISASTER_EARTHQUAKE,
    MP_DISASTER_MONSTER, MP_DISASTER_TORNADO, MP_DISASTER_MELTDOWN,
    MP_DISASTER_AIR_CRASH
} MPDisaster;

/* Overlay data for the map window. mp_get_overlay fills MP_WORLD_W*MP_WORLD_H
 * shorts, one per tile, column-major like mp_map. Growth can be negative. */
typedef enum {
    MP_OVERLAY_POPULATION = 0, MP_OVERLAY_GROWTH, MP_OVERLAY_TRAFFIC,
    MP_OVERLAY_POLLUTION, MP_OVERLAY_CRIME, MP_OVERLAY_LAND_VALUE,
    MP_OVERLAY_POLICE, MP_OVERLAY_FIRE,
    MP_OVERLAY_POWER    /* 1 where the power scan reached the tile */
} MPOverlay;
void mp_get_overlay(MPEngine *e, int which, short *out);

typedef struct {
    int yes;                /* percent who think the mayor is doing a good job */
    int problems[4];        /* CVP_* problem ids, worst first; -1 when unused */
    int problemVotes[4];    /* percent of voters naming each problem */
    long population;
    long populationDelta;   /* net migration last year */
    long assessedValue;
    int cityClass;          /* 0 village .. 5 megalopolis */
    int gameLevel;          /* 0 easy, 1 medium, 2 hard */
    int score;              /* 0..1000 */
    int scoreDelta;
} MPEvaluation;
void mp_get_evaluation(MPEngine *e, MPEvaluation *out);

typedef struct {
    long taxFund;           /* taxes collected this year */
    long roadFund, policeFund, fireFund;   /* amount requested */
} MPBudget;
void mp_get_budget(MPEngine *e, MPBudget *out);

int  mp_game_level(MPEngine *e);
/* Sets the level and the starting funds that go with it, as a new game does. */
void mp_set_game_level(MPEngine *e, int level);
void mp_set_city_name(MPEngine *e, const char *name);

/* Loads one of the 8 built-in scenarios (1 Dullsville .. 8 Rio). The engine
 * opens "cities/<file>.cty" relative to resourceDir. Returns 1 on success. */
int  mp_load_scenario(MPEngine *e, int scenario, const char *resourceDir);

/* Terrain editing: write a raw cell, and tidy river and forest edges. */
void mp_set_tile(MPEngine *e, int x, int y, unsigned short cell);
void mp_smooth_terrain(MPEngine *e);

/* Tile animation in mp_tick: off entirely, or every tick vs every other tick. */
void mp_set_animation(MPEngine *e, int animateAll, int frequent);
int  mp_animate_all(MPEngine *e);
int  mp_frequent_animation(MPEngine *e);

void mp_set_callbacks(MPEngine *e, const MPCallbacks *callbacks);

#ifdef __cplusplus
}
#endif
#endif
