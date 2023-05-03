Message Broker Application: Manages the overall message broker system, including supervision and starting other modules.

Connection: Handles TCP/UDP connections from clients (producers and consumers).

Publisher: Manages the registration and message publishing for producers.

Subscriber: Manages the registration, subscription, and message delivery for consumers.

Topic: Represents a topic that messages can be published to and consumed from.

DeadLetter: Handles messages that are deemed "unsendable" and stores them in a dead letter channel.

Serializer: Serializes and deserializes messages for network communication.

Persistence: Handles persistent messages, subscriber acknowledgments, and durable queues.

---

```mermaid
sequenceDiagram
    Consumer->>Connection: Initial connection to MessageBroker
    Connection->>Subscriber: Registration request
    Producer->>Connection: Initial connection to MessageBroker
    Connection->>Publisher: Registration request
    Subscriber->>Topic: Subscribe to a Topic
    Publisher->>Topic: Send message
    Publisher->>Persistance Handler: Persistant message
    Topic->>Subscriber: Deliver message
    Subscriber->>Persistance Handler: Send acknowledgment
    Topic->>DeadLetter: Unsendable messages
```

---

```mermaid
graph TB
    MB{"Message Broker App"}-->CS{"Connection Supervisor"}
    CS-->Connection_1
    CS-->Connection_2
    CS-->a["..."]

    MB-->PB{"Publisher Supervisor"}
    PB-->Publisher_1
    PB-->Publisher_2
    PB-->b["..."]

    MB-->SB{"Subscriber Supervisor"}
    SB-->Subscriber_1
    SB-->Subscriber_2
    SB-->c["..."]

    MB-->T{"Topic Supervisor"}
    T-->Topic_1
    T-->Topic_2
    T-->...
    
    MB-->1["DeadLetter Manager"]
    MB-->2["Serializer"]
    MB-->4["Persistance Handler"]
```