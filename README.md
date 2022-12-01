# Exhibit-Finder
Discover and set reminders for DC Smithsonian exhibits.

This app uses information from the [Smithsonian Institution](https://www.si.edu/) to provide users an easy way to discover and set reminders for exhibits at Smithsonian museums in Washington, DC. Exhibit descriptions, links to further information, and map locations ensure a user has the essential data at hand, and search features make browsing the extensive list of exhibits easy.

Users can set time based reminders to receive a notification about an exhibit for a given time and date, and also set location based reminders, which will be triggered when their device is in proximity to the relevant museum. Reminders can be readily edited and deleted from the reminders list. Maps, location services, and local notifications are used to fulfill these features.

![Screenshot of the app Exhibit Finder DC](https://i.ibb.co/d6PSVg3/Screen-Shot-2020-08-10-at-2-45-04-PM.png)

## Description
Discover and set reminders for your favorite exhibits currently on view at Smithsonian museums in Washington, D.C.!

Browse the list of current exhibits, search for museum names and exhibit descriptions, and set time or location based reminders for exhibitions you want to visit. Exhibit descriptions, locations, and links to further information will ensure the information you need is right at your fingertips.

Set time based reminders to receive exhibit notifications at your preferred time and date, and select location based reminders to be notified when your device is in proximity to the museum your chosen exhibit is displayed at. Easily refer to a list of your set reminders, and edit or delete them as needed.

Whether you are a new visitor to Washington D.C., or are familiar with the area, be certain you'll never miss out on your favorite Smithsonian exhibits before they close, or before you pass them by!

## Dependencies
[Nuke](https://github.com/kean/Nuke) is used in this project to handle image downloads and display, and [XMLParsing](https://github.com/ShawnMoore/XMLParsing) has been used to handle parsing the XML file which contains the exhibit data. [Cocoapods](https://cocoapods.org) has been used as the dependency manager for this project - please refer to Cocoapods documentation for details.

The content of the Podfile for this project is as follows:
```
  pod 'Nuke', '~> 10.7'
  pod 'XMLParsing', :git => 'https://github.com/ShawnMoore/XMLParsing.git' 
```

Pod init adds the pods to the project, then they're all set to go.

## Features
Time-based reminders allow a user to create a reminder for an exhibit, set for a specific date and time. These reminders are delivered as local notifications, which display on the device at the time specified by the user. These notifications are self-expiring and once displayed they are removed (for ease of use). A time-based reminder for an exhibit can be edited or removed at any time.

Location-based reminders use geofences to provide proximity notifications for marked exhibits. They allow a user to choose a perimeter for the notification range for the museum at which an exhibit is being shown, as well as a range for the hours of notification (this prevents geofences from being triggered during unwanted times of day, such as during the night, when a museum is closed). These reminders use location services to track the user's device location, then, when the device enters a geofence within the preferred time range the user has set, the local notification is sent. These reminders do not expire, unlike time-based notifications, but can be deleted by the user at any time. 

Any given exhibit can have a time-based reminder, a location-based remineder, or both. A tabbed view allows a user to add either reminder type, and edit any set reminders. A reminder list in the main view allows easy access to the reminders list, along with the ability to review and delete any reminder. 

The primary view lists exhibit names and locations, along with a brief description and image (loading managed by Nuke for speed and ease of use). This list is searchable by keywords that check the exhibit's name, info, and closing date. Selecting at item leads to a detail view for an exhibit includes a map view of the exhibit's museum location, and information on the exhibit such as start and end date, description, image, links to discover more, and of course a button leading to a view where the above mentioned reminders can be created. Reminders are saved in Core Data, thereby retaining all the saves, edits, and deletions made by the user. 

## Support
If you experience trouble using the app, have any questions, or simply want to contact me, you can contact me via email at kduncanwelke@gmail.com. I will be happy to discuss this project.

## Acknowledgement
This app idea was inspired by my brother (a DC resident) who frequently has missed exhibits he wished to see - with these reminders, both by time and location, he (and other visitors) can more easily ensure they see exhibits they wish to see.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/S6S03G1HT)
