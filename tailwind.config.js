/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './views/**/*.erb',
    './app.rb'
  ],
  safelist: [
    'aspect-[577/310]',
    'w-[36.0625rem]',
    'left-[max(-7rem,calc(50%-52rem))]',
    'left-[max(45rem,calc(50%+8rem))]',
    'bg-gradient-to-r',
    'from-[#ff80b5]',
    'to-[#9089fc]',
    'text-sm/6',
    'size-0.5',
    'gap-x-4',
    'gap-y-2',
    'px-3.5',
    'py-1',
    'focus-visible:outline-2',
    'focus-visible:outline-offset-2',
    'focus-visible:outline-gray-900',
    'dark:bg-white/10',
    'dark:hover:bg-white/15',
    'dark:focus-visible:outline-white'
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
