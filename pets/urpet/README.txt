== Creating a Pet with the FAT ==

=== Idle Animations ===

Create idle animations in scenes with the following names:

* content_idle
* playful_idle
* sleepy_idle
* sleeping_idle
* lonely_idle
* hungry_idle
* curious_idle
* excited_idle

These are idle animations that represent the pet's emotional states. All of the
animations exception "content_idle" are optional.

=== Walking Animations ===

Create walking animations for the various emotional states:

* content_walking
* playful_walking
* sleepy_walking
* sleeping_walking
* lonely_walking
* hungry_walking
* curious_walking
* excited_walking

All walking animations exception "content_walking" are optional. If a walking
animation for a particular emotional state is omitted, the pet will transition
from its current emotional state to "content" and then walk and then transition
back to its previous emotional state's idle animation.

=== Random Scene Selection ===

Multiple idle or walking animations can be provided and the pet will randomly
select from one when operating in that state. For example:

playful_idle_1
playful_idle_2
playful_idle_3

content_walking_1
content_walking_2

=== Transitions ===

Create transitions between emotional states for any pair of states for which a
custom transition is desired. The following transitions will be used if they
exist, but all are optional:

* content_to_playful
* content_to_excited
* content_to_curious
* content_to_hungry
* content_to_lonely

* playful_to_content
* playful_to_sleepy
* playful_to_excited

* sleepy_to_sleeping
* sleeping_to_content

* lonely_to_content
* lonely_to_sleepy

* hungry_to_content
* hungry_to_lonely
* hungry_to_curious

* curious_to_content
* curious_to_hungry
* curious_to_excited

* excited_to_content
* excited_to_playful
* excited_to_curious

An animation will run to its last frame before a new animation is started, so
as long as the idle animations all end in a neutral pose, the transitions are
not necessary. However, with transitions it is possible have the neutral pose
of a particular emotional state be different from that of the "content_idle"
neutral state.

For example, sleepy_to_sleeping could transition from content_idle's neutral
pose to a sleeping neutral pose, sleeping_idle would start and end with the
sleeping neutral pose, then sleeping_to_content would switch back from the
sleeping neutral pose to the content neutral pose.

=== ActionScript ===

Add two paths to your project path:

whirled\src\as
whirled\examples\pets\urpet\src

Create a scene and place the following ActionScript code in it:

import flash.display.MovieClip;
import flash.display.Sprite;

import flash.events.Event;

import com.whirled.PetControl;

_ctrl = new PetControl(this);
_body = new Body(_ctrl, this);
_brain = new Brain(_ctrl, _body);

var _ctrl :PetControl;
var _body :Body;
var _brain :Brain;

=== TODO ===

* more info on setting up the FAT project
* adding class paths, etc.
* put all this in the Wiki
