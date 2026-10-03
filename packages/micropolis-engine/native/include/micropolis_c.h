#ifndef MICROPOLIS_C_H
#define MICROPOLIS_C_H
#ifdef __cplusplus
extern "C" {
#endif

typedef struct MPEngine MPEngine;   /* opaque */

enum { MP_WORLD_W = 120, MP_WORLD_H = 100 };

MPEngine *mp_create(void);
void mp_destroy(MPEngine *e);

int  mp_load_city(MPEngine *e, const char *path);   /* 1 = ok, 0 = failed */
void mp_tick(MPEngine *e);                          /* simTick + animateTiles */

long mp_total_funds(MPEngine *e);
int  mp_city_year(MPEngine *e);
int  mp_city_month(MPEngine *e);

/* Pointer to MP_WORLD_W*MP_WORLD_H cells, column-major: index = x*MP_WORLD_H + y. */
const unsigned short *mp_map(MPEngine *e);

#ifdef __cplusplus
}
#endif
#endif
