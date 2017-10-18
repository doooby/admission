# Admission example: Rails app mimicking the mess of feudalism rules

## Goal
Show how to integrate Admission::ResourceArbitration into a rails app, that uses a complex case of privileges system. Each user (person) can have multiple privileges from multiple areas (countries), resulting in situations where one can do something in one area, but not in the other; where a privilege disallow doing a thing only in a single particular area. European feudalism has these wild and complex rules of inheritance, which is perfect to demonstrate how Admission's privileges one-way inheritance system deals with not that truly one-way real-world privilege inheritance system (you could've became a king -a sovereign- over a man to whom you're a vassal, resulting of insolvable situation: who's the lord to whom?).

## Integration to Rails
Admission is not meant to be only-rails privilege system. I'd like to include some helpers into the library though. This example then, is actually just a sandbox for me to find out the smoothest integration (controllers helpers, ActiveRecord to save the privileges and more).