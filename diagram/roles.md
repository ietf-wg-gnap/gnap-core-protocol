+-------------+            +------------+
|             |            |            |
|Authorization|            |  Resource  |
|   Server    |            |   Server   |
|             |<--+   +--->|            |
+-----+-------+   |   |    +------------+
      ║           |   |
      ║        +--+---+---+
      ║        |  Client  |
      ║        | Instance |
      ║        +----+-----+
      ║             ║
 .----+----.        ║      .----------.
|           |       +=====+            |
|  Resource |             |    End     |
|   Owner   | ~ ~ ~ ~ ~ ~ |    User    |
|           |             |            |
 `---------`               `----------`

Legend

===== indicates interaction between a human and computer
----- indicates interaction between two pieces of software
~ ~ ~ indicates a potential equivalence or out-of-band
          communication between roles
