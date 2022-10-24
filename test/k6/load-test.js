import http from "k6/http";

import { sleep, check } from "k6";

const cookie = __ENV.LIVEBEATS_COOKIE;

export default function () {
  const options = {
    redirects: 0,
    cookies: {
      _live_beats_key_v1: cookie,
    },
  };

  let res = http.get("http://localhost:4000/profile/settings", options);

  check(res, {
    "status 200": (r) => r.status === 200,
    "contains header": (r) => r.body.includes("Profile Settings"),
  });

  sleep(1);

  res = http.get("http://localhost:4000/glennr", options);

  check(res, {
    "songs status 200": (r) => r.status === 200,
    "contains table": (r) => r.body.includes("Artist"),
  });

  sleep(1);
}
