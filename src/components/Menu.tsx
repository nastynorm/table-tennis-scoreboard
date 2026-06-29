import {
  createSignal,
  onCleanup,
  onMount,
  Show,
  type PropsWithChildren,
} from "solid-js";

export default function Menu(props: PropsWithChildren) {
  const [open, setOpen] = createSignal(false);
  let ref!: HTMLDivElement;
  let buttonRef!: HTMLButtonElement;
  let navRef!: HTMLElement;

  const handleClick = (event: MouseEvent) => {
    if (event.target && !ref.contains(event.target as Node)) {
      setOpen(false);
    }
  };

  onMount(() => {
    if (globalThis.addEventListener) {
      globalThis.addEventListener("click", handleClick);
    }
  });

  onCleanup(() => {
    if (globalThis.removeEventListener) {
      globalThis.removeEventListener("click", handleClick);
    }
  });

  return (
    <div ref={ref} id="menu" class="fixed right-0 bottom-0 mr-2 mb-2 z-50">
      <Show when={open()}>
        <nav
          class="absolute bottom-full mb-2 right-0 z-50"
          ref={navRef}
          onClick={() => setOpen(false)}
        >
          {props.children}
        </nav>
      </Show>
      <button
        ref={buttonRef}
        id="menu-button"
        data-testid="menu-button"
        title="Menu"
        aria-label="Menu"
        onClick={() => {
          setOpen((prev) => !prev);
          buttonRef.blur();
        }}
        class="w-9 h-[18px] flex items-center justify-center bg-white rounded-md shadow-[0_1px_0_0_rgba(0,0,0,0.4)] active:translate-y-0.5 active:shadow-none transition-all selectable"
      >
        <span class="material-symbols--menu size-4"></span>
      </button>
    </div>
  );
}
