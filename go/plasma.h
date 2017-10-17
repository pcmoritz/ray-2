#include <inttypes.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void* PlasmaClient;

typedef struct {
  uint8_t data[20];
} ObjectID;

PlasmaClient PlasmaClientConnect(const char* socket);

void PlasmaClientSubscribe(PlasmaClient client, int* fd);

void PlasmaClientGetNotification(PlasmaClient client,
                                 int fd,
                                 ObjectID* object_id,
                                 int64_t* data_size,
                                 int64_t* metadata_size);

void DestroyPlasmaClient(PlasmaClient client);

#ifdef __cplusplus
}
#endif
