# 3D Holographic Radar


Created by: venomus (MrMan@mrman58.freeserve.co.uk)

Difficulty: Medium

Allright, this tutorial will add something you will find extremely cool, a 3-dimensional tactical display of the positions of players in a map! Sound cool? Read on!

Firstly, open up *misc.qc*. This is where I am going to add the main code for the radar. Go to the bottom of the file and add the following code:

```c
void() radar_think =
{
	entity head = nextent(world);
	while (head != world)
	{
		if (head.health > 0)
		{
			if (head.classname == "player")
			{
				vector bliporg = '0 0 0';
				bliporg_x = (head.origin_x / self.punchangle_x) + self.origin_x;
				bliporg_y = (head.origin_y / self.punchangle_y) + self.origin_y;
				bliporg_z = (head.origin_z / self.punchangle_z) + self.origin_z;

				entity blip = spawn();
				setorigin(blip, bliporg);
				setmodel(blip, "progs/s_bubble.spr");
				blip.think = SUB_Remove;
				blip.nextthink = time + self.cnt;
			}
		}

		head = nextent(head);
	}

	self.think = radar_think;
	self.nextthink = time + self.delay;
};
```

This function is called at a certain regular time interval (`self.delay`), and it is the code that actually scans the map for players and gets their position vectors (`head.origin` in this case). It then proceeds to do some Maths (yay! :) to these vectors.

Let me explain in more detail. Every map in Quake (in an unmodified engine anyway), has a maximum volume of 8192x8192x8192 units. The origin `'0 0 0'` of the world is in its centre, so in fact no position vector of 8192 really exists, the range of possible values in any of the three axis is -4096 to 4096. The position vector of any player found is 'scaled down' to fit the dimensions of our `func_radar` (we will set up this entity later). Imagine that the world was suddenly shrunk to a much smaller size, the size of our 3D radar display. The new position vectors of the players in the shrunken world are added to the position vector of the origin of the radar display (surprisingly enough, its centre).

Now at each of these new position vectors, a new entity is spawned for each player, a 'blip' on the radar. Each blip is represented by the bubble sprite (`"progs/s_bubble.spr"`). Each blip is set to remove itself after `self.delay` seconds, just in time for the next radar 'scan' to replace them.

Note that the size of the radar display does not have to be a perfect cube, like the world is. Each component (coordinate) of the players position vector is scaled separately, so for example you could make an almost flat, 2D display is you wanted to.

After all that, its time to add the code that initially sets up the `func_radar`. Add this code after radar_think:

```c
void() func_radar =
{
	if (!self.model)
	{
		setsize(self, '-100 -100 -100', '100 100 100');
	}
	else
	{
		setmodel(self, self.model);

		vector org = '0 0 0';
		org_x = (self.maxs_x + self.mins_x) / 2;
		org_y = (self.maxs_y + self.mins_y) / 2;
		org_z = (self.maxs_z + self.mins_z) / 2;

		setorigin(self, org);
	}

	if (!self.delay)
		self.delay = 1;

	self.punchangle = '0 0 0';
	self.punchangle_x = 8192 / self.size_x;
	self.punchangle_y = 8192 / self.size_y;
	self.punchangle_z = 8192 / self.size_z;

	self.solid = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;

	self.think = radar_think;
	self.nextthink = time + self.delay;
};
```

The normal way to set up a `func_radar` would be as a brush entity in a map. In this case, the `func_radar` function resets the brush model for the entity (you just have to do this otherwise it will not work) and then proceeds to calculate the origin for the brush model. I found out that brush models do not have a set origin position vector, not that I could access from QC code anyway. So it is neccessary to calculate the centre of the brush model, and set the origin to that.

The `.delay` field of the `func_radar` entity determines how often `radar_think` is called, and thus how often the display is updated. The process of scanning the map is pretty system intensive (ie: it could make slow computers chug like hell), especially when there are lots of players. So when you add a `func_radar` to your map think before you automatically set delay to `0.1`. I have made the default `1`, which should guarantee acceptable performance. A high `.delay` would look more like a traditional 'radar', only refreshing every few seconds or so, but may be pretty useless in a frenzied deathmatch.

Now we come to the bit of the code with `.punchangle` in it. Before you get confused, this has nothing to do with the `.punchangle` you may have encountered with weapon recoil, I just recycled that vector to avoid having to define a new one. `.punchangle` in a `func_radar` is the ratio between the world dimensions (8192 cubed) and the dimensions of our `func_radar`. In `radar_think`, it is used to calculate the positions of the 'blips' from those of the players. Because the size of a `func_radar` does not change, the size ratio is calculated once, here at the beginning.

Thats all there is to it if you want to use `func_radar` in your own map. However, the chances are you want a way of adding it to your favourite existing map, for the purpose of testing the entity if nothing else.

So, make sure *misc.qc* is saved, close it and open up *client.qc*. Go to `PutClientInServer`, and just before that function add:

```diff
 void() DecodeLevelParms;
 void() PlayerDie;
+void() func_radar;
```

Then go to the end of `PutClientInServer`, and just before

```c
spawn_tdeath (self.origin, self);
```
add

```diff
 		spawn_tfog(self.origin + v_forward*20);
 	}
 
+	if (!find(world, classname, "func_radar"))
+	{
+		entity radar = spawn();
+		radar.classname = "func_radar";
+		setorigin(radar, self.origin);
+		radar.think = func_radar;
+		radar.nextthink = time;
+	}
+
 	spawn_tdeath(self.origin, self);
```

This is just a quick hack, satisfactory to just to see the radar in a map. The first player to spawn in a map will create a `func_radar` next to them. Since this `func_radar` has no model, it will acquire the default size defined in `func_radar` (100x100x100). Add a few bots if your mod has them (Frikbots kick arse :) or indeed a few human opponents, and you should see dots other than your own moving around the display. Its difficult to see your own dot moving around, when you are yourself, moving around.

You can add all kinds of stuff to make this mod even more fun! Try making it detect monsters in single-player. Use different sprites (or models) for different targets. When doing this, you will have to make sure everything is precached (the bubble sprite is already precached in worldspawn). You can pre-cache new stuff in `func_radar` as long as the entity is part of a map (ie: not my `PutClientInServer` hack), otherwise you'll have to precache in worldspawn (in world.qc).

My `func_radar` is a full on, 3D hologram. You may prefer a 2D panel, such that it could be on a wall or table. If you wanted a flat, horizonal, top-down view you could just make the `func_radar` brush flat, but removing all the unneeded z-axis code would yield a slight performance improvement. If you wanted to make a top-down view, but have the radar panel hanging on a wall, you would have to switch some of the axis around. I'm not going into details here, just giving a few pointers should you want to customise my mod to your own specifications.

Enjoy your radar fun!

