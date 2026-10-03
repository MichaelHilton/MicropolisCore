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
void mp_generate_map(MPEngine *e, int seed);
int  mp_do_tool(MPEngine *e, int tool, int x, int y);
int  mp_save_city(MPEngine *e, const char *path);
void mp_make_disaster(MPEngine *e, int which);

int  mp_get_sprites(MPEngine *e, MPSprite *out, int maxCount);
void mp_get_history(MPEngine *e, int which, short *out);

#ifdef __cplusplus
}
#endif
#endif
