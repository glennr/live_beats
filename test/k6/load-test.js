import http from "k6/http";

import { sleep, check } from "k6";

export const options = {
  cookie: __ENV.LIVEBEATS_COOKIE,
};

export default function () {
  const res = http.get("http://localhost:4000/profile/settings", {
    redirects: 0,
    cookies: {
      _live_beats_key_v1: options.cookie,
    },
  });

  check(res, {
    "status 200": (r) => r.status === 200,
    "contains header": (r) => r.body.includes("Profile Settings"),
  });

  sleep(1);
}
