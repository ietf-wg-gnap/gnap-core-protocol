+--------+                                  +--------+          .----.
| Client |                                  |   AS   |         | End  |
|Instance|                                  |        |         | User |
|        +--(1)--- Request Access --------->|        |         |      |
|        |                                  |        |         |      |
|        |<-(2)-- Interaction Needed -------+        |         |      |
|        |                                  |        |         |      |
|        +==(3)== Facilitate Interaction =====================>|      |
|        |                                  |        |         +------+
|        |                                  |        |<==(4)==>|  RO  |
|        |                                  |        |  AuthN  |      |
|        |                                  |        |         |      |
|        |                                  |        |<==(5)==>|      |
|        |                                  |        |  AuthZ  +------+
|        |                                  |        |         | End  |
|        |<=(6)== Signal Continuation =========================+ User |
|        |                                  |        |          `----`
|        +--(7)--- Continue Request ------->|        |
|        |                                  |        |
|        |<-(8)----- Grant Access ----------+        |
|        |                                  |        |
+--------+                                  +--------+
