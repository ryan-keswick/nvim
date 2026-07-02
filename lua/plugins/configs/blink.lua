return {
  -- super-tab preserves the cmp muscle memory: Tab accepts / jumps through
  -- snippet placeholders in insert mode. Normal-mode Tab buffer cycling in
  -- mappings.lua is a different mode and is unaffected.
  keymap = { preset = "super-tab" },

  snippets = { preset = "luasnip" },

  sources = {
    default = { "lazydev", "lsp", "path", "snippets", "buffer" },
    providers = {
      lazydev = {
        name = "LazyDev",
        module = "lazydev.integrations.blink",
        -- rank nvim-runtime completions above other lua sources
        score_offset = 100,
      },
    },
  },
}
