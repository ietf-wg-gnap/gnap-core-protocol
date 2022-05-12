 .----------.           .----------.
|  End user  | ~ ~ ~ ~ |  Resource  |
|            |         | Owner (RO) |
 `----+-----`           `-----+----`
      ║                       ║
      ║                       ║
     (A)                     (B)
      ║                       ║
      ║                       ║
+-----+--+                    ║           +------------+
| Client | (1)                ║           |  Resource  |
|Instance|                    ║           |   Server   |
|        |        +-----------+---+       |    (RS)    |
|        +--(2)-->| Authorization |       |            |
|        |<-(3)---+     Server    |       |            |
|        |        |      (AS)     |       |            |
|        +--(4)-->|               |       |            |
|        |<-(5)---+               |       |            |
|        |        |               |       |            |
|        +---------------(6)------------->|            |
|        |        |               |   (7) |            |
|        |<--------------(8)------------->|            |
|        |        |               |       |            |
|        +--(9)-->|               |       |            |
|        |<-(10)--+               |       |            |
|        |        |               |       |            |
|        +---------------(11)------------>|            |
|        |        |               |  (12) |            |
|        +--(13)->|               |       |            |
|        |        |               |       |            |
+--------+        +---------------+       +------------+

Legend
===== indicates a possible interaction with a human
----- indicates an interaction between protocol roles
~ ~ ~ indicates a potential equivalence or out-of-band
        communication between roles
