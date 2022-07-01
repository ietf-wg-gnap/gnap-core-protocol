                                                       .-----.
                                                      |       |
                                               +------+--+    | Continue
                      .---Need Interaction---->|         |    |
                     /                         | Pending |<--`
                    /   .--Finish Interaction--+         |
                   /   /     (approve/deny)    +----+----+
                  /   /                             |
                 /   /                              | Cancel
                /   v                               v
             +-+----------+                   +===========+
             |            |                   ║           ║
---Request-->| Processing +------Finalize---->║ Finalized ║
             |            |                   ║           ║
             +-+----------+                   +===========+
                \    ^                              ^
                 \    \                             | Revoke or
                  \    \                            | Finalize
                   \    \                     +-----+----+
                    \    `-----Update---------+          |
                     \                        | Approved |<--.
                      `-----No Interaction--->|          |    |
                                              +-------+--+    | Continue
                                                      |       |
                                                       `-----`
