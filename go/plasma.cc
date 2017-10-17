#include "plasma.h"

#include <plasma/client.h>

PlasmaClient PlasmaClientConnect(const char* socket) {
  auto c = new plasma::PlasmaClient();
  ARROW_CHECK_OK(c->Connect(std::string(socket), std::string(""), 64));
  return reinterpret_cast<void*>(c);
}

void PlasmaClientSubscribe(PlasmaClient client, int* fd) {
  auto c = reinterpret_cast<plasma::PlasmaClient*>(client);
  ARROW_CHECK_OK(c->Subscribe(fd));
}

void PlasmaClientGetNotification(PlasmaClient client,
                                 int fd,
                                 ObjectID* object_id,
                                 int64_t* data_size,
                                 int64_t* metadata_size) {
  auto c = reinterpret_cast<plasma::PlasmaClient*>(client);
  ARROW_CHECK_OK(c->GetNotification(fd, reinterpret_cast<plasma::ObjectID*>(object_id), data_size, metadata_size));
}

void DestroyPlasmaClient(PlasmaClient client) {
  delete reinterpret_cast<plasma::PlasmaClient*>(client);
}
