# Changelog

## v1.4
- Prevent Japanese character variants (e.g. 毎 instead of 每) from appearing as candidates

## v1.3
- Added full-width zero ("〇") as another way to represent zero (in addition to "零") for the "ling2" reading

## v1.2
- Improved ranking of several characters for which tone frequency data was incorrect or incomplete
- Rolled back systemwide keyboard install instructions, as the button to open app settings directly does not always work correctly
- Added help documentation for the ability to indicate rare tones

## v1.1
- A number of small fixes and changes were made to the tutorial text and order
- There is now an option to display an asterisk next to candidates which are relatively rare choices for the given reading/tone
- Heteronyms (e.g. 还 read as huan2 or hai2) are now ordered much more reasonably thanks to data from Unihan
- The candidate scrollview now resets to the left when the candidates change
- Better test coverage, particularly for the candidate dictionary
- Add an entry in Settings.app (a settings bundle), which simplifies enabling the keyboard
- Make the keyboard UI more consistent with the system keyboard
- Fixed a bug causing home-row keys to be too large with shift/capslock

## v1.0
This is the initial release available on the app store.
