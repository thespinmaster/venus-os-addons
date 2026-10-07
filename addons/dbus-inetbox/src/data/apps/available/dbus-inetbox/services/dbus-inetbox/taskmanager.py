import asyncio
import logging
from typing import Any, Callable, Coroutine, Optional, List, Tuple

class TaskManager:
	"""
	TaskManager

	Lightweight manager that repeatedly schedules a set of zero-argument coroutine-producing callbacks
	as asyncio.Task instances.

	Description:
	- Each registered callback must be a callable that returns a coroutine when called (typically a
		reference to an async function, e.g. async def worker(...)).
	- The public add_task method appends such callbacks to an internal list.
	- main_loop is an async, never-ending loop that:
			* builds a local list of task handles once at start (length == number of registered callbacks at
				that moment),
			* for each callback index, creates a new asyncio.Task from the callback when there is no task
				present or the previous task is done,
			* sleeps WAIT_BETWEEN_TASKS_SEC seconds between iterations.

	Attributes:
			WAIT_BETWEEN_TASKS_SEC (float): Delay, in seconds, between loop iterations.
					_tasks_callbacks (List[Tuple[str, Callable[[], Coroutine[Any, Any, None]], Optional[asyncio.Task]]]): Class-level list of tuples `(name, callback, task)` where `callback` is the callable and `task` is the running `asyncio.Task` or `None`. NOTE: this is a mutable class attribute and is shared across all TaskManager instances.

	Methods:
			add_task(callback):
					Register a zero-argument callable that returns a coroutine. The callable will be invoked
					inside the main loop to create a task.

			main_loop():
					Async infinite loop that ensures each registered callback has a corresponding running task
					(or will recreate it once the previous run completes). Intended to be run inside an
					asyncio event loop (e.g., via asyncio.create_task(manager.main_loop()) or await).

	Behavioral notes and caveats:
	- _tasks_callbacks being a class attribute means callbacks are shared between instances; if
		per-instance storage is desired, move initialization to __init__.
	- The tasks list is created once when main_loop starts; callbacks added after main_loop begins
		will not be included in that run unless main_loop is restarted or modified to handle dynamic size.
	- Exceptions raised inside individual tasks are not caught by TaskManager; handle exceptions inside
		callbacks or monitor tasks via their result()/exception() or add_done_callback.
	- main_loop does not provide a built-in shutdown mechanism; cancel the returned asyncio.Task or add
		cooperative cancellation logic to stop the loop cleanly.
	- The class is not thread-safe and is intended to be used from a single asyncio event loop.

	Example:
			async def worker():
					# do async work
					...

			tm = TaskManager()
			tm.add_task(worker)
			await tm.main_loop()
	"""
	WAIT_BETWEEN_TASKS_SEC : float = 10

	# List entries: (name, callback, task) where `task` is Optional[asyncio.Task]
	_tasks_callbacks: List[Tuple[str, Callable[[], Coroutine[Any, Any, None]],
								 Optional[asyncio.Task]]] = []

	def add_task(self, name: str, callback: Callable[[], Coroutine[Any, Any, None]]):
		self._tasks_callbacks.append((name, callback, None))

	"""
	Run an indefinite asynchronous monitoring loop that ensures registered background
	tasks are active.
	This coroutine iterates over self._tasks_callbacks, which is expected to be a list
	of tuples of the form (name: str, callback: Callable[[], Coroutine], task: Optional[asyncio.Task]).
	For each entry, if the task is None or has completed (task.done()), the method
	schedules a new task from the callback using asyncio.create_task and replaces the
	list element with a new tuple containing the created Task (tuples are immutable,
	so the list element must be reassigned).
	Between iterations the loop awaits for self.WAIT_BETWEEN_TASKS_SEC seconds. The
	loop runs until the coroutine is cancelled or the program exits.
	Notes:
	- Callbacks should be async callables (coroutines) that can be awaited.
	- Any exceptions raised while creating tasks will propagate to the caller unless
		handled elsewhere.
	- This coroutine may be cancelled by cancelling the created Task; callers should
		handle asyncio.CancelledError if necessary.
	"""
	async def main_loop(self):
		print("main_loop task in")
		try:
			while True:
					for i in range(len(self._tasks_callbacks)):
							name, cb, task = self._tasks_callbacks[i]
							if task is None or task.done():
									print(f"Creating task {name}")
									# Tuples are immutable; reassign the list element with the new task instance.
									self._tasks_callbacks[i] = (name, cb, asyncio.create_task(cb()))

					print(f"main_loop sleeping for {self.WAIT_BETWEEN_TASKS_SEC} secs")
					await asyncio.sleep(self.WAIT_BETWEEN_TASKS_SEC)
		except Exception as ex:
			logging.error("Error in published_inetbox_value %s" % (ex))
