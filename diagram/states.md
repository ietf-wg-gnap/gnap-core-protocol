                                                       .-----.
                                                      |       |
                                               +------+--+    | Continue
                      .---Need Interaction---->|         |    |
                     /                         | Pending |<--`
                    /   .--Finish Interaction--+         |
                   /   /                       +----+----+
                  /   /                             |
                 /   /                              | Cancel
                /   v                               v
             +-+----------+                    +=========+
             |            |                    ║         ║
---Request-->| Processing +-------Revoke------>║ Revoked ║
             |            |                    ║         ║
             +-+----------+                    +=========+
                \    ^                              ^
                 \    \                             | Revoke
                  \    \                            |
                   \    \                     +-----+----+
                    \    `-----Update---------+          |
                     \                        | Approved |<--.
                      `-----No Interaction--->|          |    |
                                              +-------+--+    | Continue
                                                      |       |
                                                       `-----`
