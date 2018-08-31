
This repo is an "transition" set of reclass classes used under salt-formulas (https://github.com/salt-formulas).

Folders:
- *source* - sources, as copied from formulas and shared "system-level"
- *merged* - processed, merged source into an unified structure, per formula

It merges reclass "classes" from (source):
- individual formulas (`/srv/salt/reclass/classes/service` -> `<formula>/metadata/service`)
- shared system level (`/srv/salt/reclass/classes/system` -> https://github.com/Mirantis/reclass-system-salt-model)

into an single model.

Expected usage:
- source of the best-practice and production setup
- unified "shared" part of the new reclass model

I personally use this structure as "source" for my new reclass models.


