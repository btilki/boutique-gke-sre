# Terraform modules

Reusable GCP infrastructure modules. Each module documents purpose, inputs, outputs, dependencies, and usage in its `README.md`.

| Module                                        | Phase | Status                                            |
| --------------------------------------------- | ----- | ------------------------------------------------- |
| [project-apis](project-apis/)                 | 1     | Implemented                                       |
| [networking](networking/)                     | 1     | Implemented                                       |
| [gke](gke/)                                   | 2     | Implemented                                       |
| [dns](dns/)                                   | 2     | Implemented                                       |
| [ingress-edge](ingress-edge/)                 | 2     | Implemented                                       |
| [wif](wif/)                                   | 3     | Implemented                                       |
| [artifact-registry](artifact-registry/)       | 3     | Implemented                                       |
| [binary-authorization](binary-authorization/) | 3     | Implemented                                       |
| [iam](iam/)                                   | 3–4   | Scaffold (README only — WI bindings via topic 10) |
| [secret-manager](secret-manager/)             | 4     | Scaffold (README only — secrets via gcloud / ESO) |
| [monitoring](monitoring/)                     | 9-C   | Implemented                                       |
| [armor](armor/)                               | 7     | Implemented                                       |
| [backup](backup/)                             | 9-C   | Implemented                                       |
